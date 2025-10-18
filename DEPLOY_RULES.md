# Deploy Updated Firebase Rules

## Issue Fixed
The database permission denied error was caused by mismatched validation rules. The rules expected `mealSelections` and `totalAmount` fields, but the code was sending `mealType`, `foodType`, and `amount` fields.

## Deploy Rules to Firebase

### Option 1: Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Realtime Database** → **Rules**
4. Copy all the contents from `database.rules.json` file
5. Paste it into the rules editor
6. Click **Publish**

### Option 2: Firebase CLI

```bash
# If you haven't installed Firebase CLI yet
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy the rules
firebase deploy --only database
```

## What Was Changed

Updated the `preorders` validation rules to match the actual data structure:

**Old fields (causing errors):**
- `mealSelections` (object)
- `totalAmount` (number)

**New fields (now working):**
- `mealType` (string) - e.g., "breakfast", "lunch", "dinner"
- `foodType` (string) - e.g., "Vegetable", "Fish_Egg", "Chicken"
- `amount` (number) - price of individual meal

## After Deploying

1. Restart your app
2. Try placing a meal order
3. You should no longer see "permission denied" errors

## Verify Deployment

In Firebase Console → Realtime Database → Rules, you should see:
```json
"preorders": {
  "$date": {
    "$orderId": {
      ".validate": "newData.hasChildren(['orderId', 'userId', 'userEmail', 'userName', 'orderDate', 'orderTime', 'mealType', 'foodType', 'amount', 'status'])",
      ...
    }
  }
}
```

