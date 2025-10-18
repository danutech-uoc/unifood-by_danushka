import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize database rules and structure
  Future<void> initializeDatabase() async {
    try {
      // Check if analytics node exists, if not create it
      final analyticsSnapshot = await _database.child('canteen_analytics').once();
      if (!analyticsSnapshot.snapshot.exists) {
        await _database.child('canteen_analytics').set({
          'todayOrders': 0,
          'totalRevenue': 0,
          'breakfastOrders': 0,
          'lunchOrders': 0,
          'dinnerOrders': 0,
        });
      }

      // Initialize order deadlines
      final deadlinesSnapshot = await _database.child('order_deadlines').once();
      if (!deadlinesSnapshot.snapshot.exists) {
        await _database.child('order_deadlines').set({
          'breakfast': {
            'isActive': true,
            'startTime': '15:00',  // 3 PM
            'endTime': '23:00',    // 11 PM
            'description': 'Order tomorrow\'s breakfast today',
          },
          'lunch': {
            'isActive': true,
            'startTime': '06:00',  // 6 AM
            'endTime': '10:00',    // 10 AM
            'description': 'Order today\'s lunch',
          },
          'dinner': {
            'isActive': true,
            'startTime': '12:00',  // 12 PM
            'endTime': '16:00',    // 4 PM
            'description': 'Order today\'s dinner',
          },
        });
      }
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  // Place a pre-order
  Future<bool> placePreOrder({
    required String mealType,
    required Map<String, dynamic> mealData,
    required String dateString,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userId = user.uid;
      final userEmail = user.email ?? '';
      final userName = user.displayName ?? 'User';

      // Generate order ID
      final orderId = '${userId}_${DateTime.now().millisecondsSinceEpoch}_$mealType';

      final orderData = {
        'orderId': orderId,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'orderDate': dateString,
        'orderTime': ServerValue.timestamp,
        'mealType': mealType,
        'foodType': mealData['mealType'],
        'amount': mealData['price'],
        'status': 'pending',
        'deadline': _getMealDeadline(mealType).millisecondsSinceEpoch,
      };

      // Save order under date structure
      await _database.child('preorders').child(dateString).child(orderId).set(orderData);

      // Update analytics
      await _updateAnalytics(mealType, mealData['mealType'], mealData['price']);

      return true;
    } catch (e) {
      print('Error placing pre-order: $e');
      return false;
    }
  }

  // Get meal counts for a specific date
  Future<Map<String, int>> getMealCounts(String dateString) async {
    try {
      final snapshot = await _database
          .child('preorders')
          .child(dateString)
          .once();

      final Map<String, int> counts = {};

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final order = value as Map<dynamic, dynamic>;
          final mealType = order['mealType'] as String?;
          final foodType = order['foodType'] as String?;

          if (mealType != null && foodType != null) {
            final key = '${mealType}_${foodType}';
            counts[key] = (counts[key] ?? 0) + 1;
          }
        });
      }

      return counts;
    } catch (e) {
      print('Error getting meal counts: $e');
      return {};
    }
  }

  // Get canteen analytics
  Future<Map<String, dynamic>> getCanteenAnalytics() async {
    try {
      final snapshot = await _database.child('canteen_analytics').once();
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      print('Error getting analytics: $e');
      return {};
    }
  }

  // Update analytics when an order is placed
  Future<void> _updateAnalytics(String mealType, String foodType, int price) async {
    try {
      final analyticsRef = _database.child('canteen_analytics');
      
      // Get current analytics
      final snapshot = await analyticsRef.once();
      Map<String, dynamic> analytics = {};
      
      if (snapshot.snapshot.exists) {
        analytics = Map<String, dynamic>.from(snapshot.snapshot.value as Map<dynamic, dynamic>);
      }

      // Update counts
      analytics['todayOrders'] = (analytics['todayOrders'] ?? 0) + 1;
      analytics['${mealType}Orders'] = (analytics['${mealType}Orders'] ?? 0) + 1;
      
      // Update revenue
      analytics['totalRevenue'] = (analytics['totalRevenue'] ?? 0) + price;

      // Save updated analytics
      await analyticsRef.set(analytics);
    } catch (e) {
      print('Error updating analytics: $e');
    }
  }

  // Get meal deadline
  DateTime _getMealDeadline(String mealType) {
    final now = DateTime.now();
    if (mealType.toLowerCase() == 'breakfast') {
      // Breakfast deadline: 11 PM same day
      return DateTime(now.year, now.month, now.day, 23, 0);
    } else if (mealType.toLowerCase() == 'lunch') {
      // Lunch deadline: 11 AM same day
      return DateTime(now.year, now.month, now.day, 11, 0);
    } else {
      // Dinner deadline: 6 PM same day
      return DateTime(now.year, now.month, now.day, 18, 0);
    }
  }

  // Check if user has already ordered for a specific date and meal type
  Future<bool> hasUserOrdered(String dateString, String mealType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _database
          .child('preorders')
          .child(dateString)
          .once();

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        return data.values.any((order) {
          final orderData = order as Map<dynamic, dynamic>;
          return orderData['userId'] == user.uid && orderData['mealType'] == mealType;
        });
      }
      return false;
    } catch (e) {
      print('Error checking user order: $e');
      return false;
    }
  }

  // Get user's orders for a specific date
  Future<List<Map<String, dynamic>>> getUserOrders(String dateString) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _database
          .child('preorders')
          .child(dateString)
          .once();

      final List<Map<String, dynamic>> orders = [];

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final order = value as Map<dynamic, dynamic>;
          if (order['userId'] == user.uid) {
            orders.add(Map<String, dynamic>.from(order));
          }
        });
      }

      return orders;
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  // Cancel an order
  Future<bool> cancelOrder(String orderId, String dateString) async {
    try {
      await _database.child('preorders').child(dateString).child(orderId).remove();
      return true;
    } catch (e) {
      print('Error canceling order: $e');
      return false;
    }
  }

  // Get order deadlines
  Future<Map<String, dynamic>> getOrderDeadlines() async {
    try {
      final snapshot = await _database.child('order_deadlines').once();
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      print('Error getting order deadlines: $e');
      return {};
    }
  }

  // Get meal prices
  Future<Map<String, dynamic>> getMealPrices() async {
    try {
      final snapshot = await _database.child('system_config/mealPrices').once();
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        return Map<String, dynamic>.from(data);
      }
      return {};
    } catch (e) {
      print('Error getting meal prices: $e');
      return {};
    }
  }

  // Save user details on first login/signup
  Future<bool> saveUserDetails(User user) async {
    try {
      final userId = user.uid;
      final userRef = _database.child('users').child(userId);
      
      // Check if user already exists
      final snapshot = await userRef.once();
      
      if (!snapshot.snapshot.exists) {
        // New user - save details (matching the rules structure)
        await userRef.set({
          'uid': userId,
          'email': user.email ?? '',
          'displayName': user.displayName ?? 'User',
          'createdAt': ServerValue.timestamp,
        });
      } else {
        // Existing user - update last login
        await userRef.update({
          'lastLoginAt': ServerValue.timestamp,
        });
      }
      
      return true;
    } catch (e) {
      print('Error saving user details: $e');
      return false;
    }
  }
}