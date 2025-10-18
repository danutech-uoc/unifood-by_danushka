@echo off
echo ========================================
echo UniFood Build Script
echo ========================================
echo.

echo Step 1: Stopping Gradle Daemons...
cd android
call gradlew --stop
cd ..
echo.

echo Step 2: Cleaning project...
call flutter clean
echo.

echo Step 3: Getting dependencies...
call flutter pub get
echo.

echo Step 4: Building and running app...
call flutter run

echo.
echo ========================================
echo Build process complete!
echo ========================================
pause

