@echo off
echo Getting SHA-1 fingerprint for Google Sign-In configuration...
echo.
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
echo.
echo Copy the SHA-1 fingerprint above and add it to your Firebase project settings.
echo Go to: https://console.firebase.google.com/
echo Select your project -> Project Settings -> Your apps -> Android app -> Add fingerprint
pause
