# Admin Analytics Date Fix

## Problem
The admin dashboard was not correctly showing today's meal order counts when users booked meals. Specifically:
- When users ordered **lunch** (6 AM - 11 AM) for today, the admin would see it counted in **tomorrow's** data
- When users ordered **dinner** (12 PM - 6 PM) for today, the admin would see it counted in **tomorrow's** data
- Only **breakfast** orders (3 PM - 11 PM) should be counted for tomorrow

## Root Cause
The issue was in `lib/services/database_service.dart` in the `_getOrderTargetDate()` method:

```dart
// OLD CODE (INCORRECT)
bool hasBreakfastOrLunch = false;
mealSelections.forEach((mealType, mealData) {
  if ((mealType == 'breakfast' || mealType == 'lunch') &&
      mealData is Map &&
      mealData['selected'] == true) {
    hasBreakfastOrLunch = true;
  }
});

// If breakfast or lunch is selected, order is for tomorrow
if (hasBreakfastOrLunch) {
  return tomorrow;  // ❌ WRONG! Lunch should be TODAY
}
```

The code was treating **lunch** orders the same as **breakfast** orders, counting them for tomorrow instead of today.

## Solution

### 1. Fixed `_getOrderTargetDate()` Method
Updated the logic to check each meal type individually and use the correct target date:

```dart
// NEW CODE (CORRECT)
bool hasTodayMeal = false;
bool hasTomorrowMeal = false;

mealSelections.forEach((mealType, mealData) {
  if (mealData is Map && mealData['selected'] == true) {
    final targetDate = getOrderTargetDate(mealType);  // Uses correct logic per meal type
    if (targetDate.day == today.day) {
      hasTodayMeal = true;
    } else {
      hasTomorrowMeal = true;
    }
  }
});

// If there are meals for today, use today's date
if (hasTodayMeal) {
  return today;  // ✅ CORRECT!
}
```

### 2. Refactored `placePreOrder()` Method
Updated to process each meal type separately with its own target date:

- **Before**: All meals in an order were saved under a single date
- **After**: Each meal is saved under its correct target date
  - Breakfast → Tomorrow's date
  - Lunch → Today's date
  - Dinner → Today's date

### 3. Added New Helper Methods
Created two new methods to handle individual meal updates:

1. **`_updateDailyMealCountForMeal()`** - Updates meal counts for a specific meal on its target date
2. **`_updateAnalyticsForMeal()`** - Updates analytics incrementally for a specific meal on its target date

## Benefits

### ✅ Correct Date Allocation
- **Breakfast orders** (3 PM - 11 PM) → Counted for **tomorrow**
- **Lunch orders** (6 AM - 11 AM) → Counted for **today**
- **Dinner orders** (12 PM - 6 PM) → Counted for **today**

### ✅ Accurate Real-Time Analytics
- Admin can see today's lunch and dinner orders immediately
- Analytics update correctly as orders are placed
- Revenue tracking is accurate per day

### ✅ Mixed Order Support
If a user orders multiple meals in one transaction:
- Each meal is counted on its appropriate date
- Example: Order placed at 4 PM with lunch + breakfast:
  - Lunch → Counted for today
  - Breakfast → Counted for tomorrow

## Testing Recommendations

1. **Test Lunch Order (Morning)**
   - Time: Between 6 AM - 11 AM
   - Order: Lunch
   - Expected: Should appear in **today's** admin dashboard

2. **Test Dinner Order (Afternoon)**
   - Time: Between 12 PM - 6 PM
   - Order: Dinner
   - Expected: Should appear in **today's** admin dashboard

3. **Test Breakfast Order (Evening)**
   - Time: Between 3 PM - 11 PM
   - Order: Breakfast
   - Expected: Should appear in **tomorrow's** admin dashboard

4. **Test Mixed Order**
   - Time: Between 3 PM - 6 PM
   - Order: Dinner + Breakfast
   - Expected:
     - Dinner → Today's dashboard
     - Breakfast → Tomorrow's dashboard

## Files Modified
- `lib/services/database_service.dart`
  - Fixed `_getOrderTargetDate()` method
  - Refactored `placePreOrder()` method
  - Added `_updateDailyMealCountForMeal()` method
  - Added `_updateAnalyticsForMeal()` method

## Build Status
✅ Build successful - APK generated without errors

