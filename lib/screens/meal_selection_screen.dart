import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/database_service.dart';

class MealSelectionScreen extends StatefulWidget {
  const MealSelectionScreen({super.key});

  @override
  State<MealSelectionScreen> createState() => _MealSelectionScreenState();
}

class _MealSelectionScreenState extends State<MealSelectionScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic> _orderDeadlines = {};
  Map<String, dynamic> _mealPrices = {};
  Map<String, bool> _selectedMeals = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
  };
  Map<String, String> _selectedFoodTypes = {
    'breakfast': '',
    'lunch': '',
    'dinner': '',
  };
  
  // Predefined food types
  final List<String> _foodTypes = [
    'Vegetable',
    'Chicken', 
    'Fish',
    'Egg',
  ];
  
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load order deadlines
      final deadlinesSnapshot = await _database.child('order_deadlines').once();
      if (deadlinesSnapshot.snapshot.exists) {
        setState(() {
          _orderDeadlines = Map<String, dynamic>.from(deadlinesSnapshot.snapshot.value as Map<dynamic, dynamic>);
        });
      }

      // Use predefined food types instead of loading from database
      setState(() {
        _mealPrices = {};
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isOrderWindowOpen(String mealType) {
    if (!_orderDeadlines.containsKey(mealType)) return false;
    
    final deadline = _orderDeadlines[mealType];
    if (!deadline['isActive']) return false;
    
    final now = DateTime.now();
    final startTime = deadline['startTime'] as String;
    final endTime = deadline['endTime'] as String;
    
    // Parse time strings (format: "HH:MM")
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.add(Duration(hours: startHour, minutes: startMinute));
    final windowEnd = today.add(Duration(hours: endHour, minutes: endMinute));
    
    return now.isAfter(windowStart) && now.isBefore(windowEnd);
  }

  Duration _getTimeUntilNextWindow(String mealType) {
    if (!_orderDeadlines.containsKey(mealType)) return Duration.zero;
    
    final deadline = _orderDeadlines[mealType];
    final startTime = deadline['startTime'] as String;
    
    final now = DateTime.now();
    final startParts = startTime.split(':');
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    
    final today = DateTime(now.year, now.month, now.day);
    var windowStart = today.add(Duration(hours: startHour, minutes: startMinute));
    
    // If window start is in the past today, check tomorrow
    if (windowStart.isBefore(now)) {
      windowStart = windowStart.add(const Duration(days: 1));
    }
    
    return windowStart.difference(now);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  List<String> get _availableFoodTypes => _foodTypes;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Food'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Meal Cards
              _buildMealCard('breakfast', 'Breakfast', Icons.free_breakfast, Colors.orange),
              
              const SizedBox(height: 16),
              
              _buildMealCard('lunch', 'Lunch', Icons.lunch_dining, Colors.orange),
              
              const SizedBox(height: 16),
              
              _buildMealCard('dinner', 'Dinner', Icons.dinner_dining, Colors.blue),
              
              const SizedBox(height: 24),
              
              // Place Order Button
              if (_selectedMeals.values.any((selected) => selected))
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _placeOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Place Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(String mealType, String title, IconData icon, Color iconColor) {
    final isOpen = _isOrderWindowOpen(mealType);
    final timeUntilNext = _getTimeUntilNextWindow(mealType);
    final deadline = _orderDeadlines[mealType] ?? {};
    final startTime = deadline['startTime'] ?? '00:00';
    final endTime = deadline['endTime'] ?? '00:00';
    final description = deadline['description'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen ? Colors.green.shade300 : Colors.grey.shade300,
          width: isOpen ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startTime - $endTime',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOpen ? 'OPEN' : 'CLOSED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          
          if (!isOpen) ...[
            const SizedBox(height: 8),
            Text(
              'Next window opens in: ${_formatDuration(timeUntilNext)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Toggle Switch and Food Type Selection
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Select ${title.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _selectedMeals[mealType] ?? false,
                      onChanged: isOpen ? (value) {
                        setState(() {
                          _selectedMeals[mealType] = value;
                          if (!value) {
                            _selectedFoodTypes[mealType] = '';
                          }
                        });
                      } : null,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Food Type Selection
          if (_selectedMeals[mealType] ?? false) ...[
            const SizedBox(height: 16),
            const Text(
              'Choose Your Food Type:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableFoodTypes.map((foodType) {
                final isSelected = _selectedFoodTypes[mealType] == foodType;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFoodTypes[mealType] = foodType;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        foodType,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.green.shade700 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _placeOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Please log in first';
          _isLoading = false;
        });
        return;
      }

      final today = DateTime.now();
      int successCount = 0;
      
      for (final mealType in _selectedMeals.keys) {
        if (_selectedMeals[mealType] == true && _selectedFoodTypes[mealType]!.isNotEmpty) {
          final foodType = _selectedFoodTypes[mealType]!;
          
          // Determine the correct date for the order
          // Breakfast is for tomorrow, lunch and dinner are for today
          DateTime orderDate;
          if (mealType == 'breakfast') {
            orderDate = today.add(const Duration(days: 1));
          } else {
            orderDate = today;
          }
          
          final dateString = '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';
          
          final mealData = {
            'mealType': foodType,
            'description': 'Delicious $foodType for $mealType',
          };

          final success = await _databaseService.placePreOrder(
            mealType: mealType,
            mealData: mealData,
            dateString: dateString,
          );

          if (success) {
            successCount++;
          }
        }
      }

      if (successCount > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully placed $successCount order(s)!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset selections
        setState(() {
          _selectedMeals = {
            'breakfast': false,
            'lunch': false,
            'dinner': false,
          };
          _selectedFoodTypes = {
            'breakfast': '',
            'lunch': '',
            'dinner': '',
          };
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to place orders. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error placing orders: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}