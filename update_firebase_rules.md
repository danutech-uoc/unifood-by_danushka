# Firebase Database Rules Update

## Current Issues with Your Database Rules:

1. **Admin Authentication Problem**: The rules check for `auth.token.email === 'admin@gmail.com'` but this doesn't work reliably with Google Sign-In tokens.

2. **User Data Structure**: The rules expect different field names than what our app is using.

## 🔧 **Solution: Update Your Firebase Rules**

### **Step 1: Copy the Updated Rules**

I've created an updated rules file (`database_rules_updated.json`) that fixes these issues:

- ✅ Removed problematic admin email checks
- ✅ Simplified authentication to work with Google Sign-In
- ✅ Fixed user data structure to match our app
- ✅ Made rules more permissive for development

### **Step 2: Apply the Rules in Firebase Console**

1. **Go to [Firebase Console](https://console.firebase.google.com/)**
2. **Select your project: "uni-food-flutter"**
3. **Go to "Realtime Database" → "Rules" tab**
4. **Replace the entire rules content with the updated rules from `database_rules_updated.json`**
5. **Click "Publish"**

### **Step 3: Test the App**

After updating the rules:
1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Try Google Sign-In again** - it should work now!

## 🚨 **Important Notes:**

- The updated rules are more permissive for development
- All authenticated users can read/write most data
- This is suitable for development but should be tightened for production
- The rules still validate data structure and types

## 🔒 **For Production (Later):**

When you're ready for production, you can add back more restrictive rules, but for now, these rules will allow your app to work properly with Google Sign-In.
