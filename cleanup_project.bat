@echo off
echo UniFood Project Cleanup
echo =====================
echo.

echo Cleaning Flutter build files...
flutter clean

echo.
echo Removing temporary files...
if exist "build" rmdir /s /q "build"
if exist ".dart_tool" rmdir /s /q ".dart_tool"
if exist ".flutter-plugins" del ".flutter-plugins"
if exist ".flutter-plugins-dependencies" del ".flutter-plugins-dependencies"
if exist ".packages" del ".packages"

echo.
echo Removing backup files...
del /q "*.backup" 2>nul
del /q "*.bak" 2>nul
del /q "*.tmp" 2>nul

echo.
echo Removing IDE files...
if exist ".vscode" rmdir /s /q ".vscode"
if exist ".idea" rmdir /s /q ".idea"

echo.
echo Project cleanup completed!
echo.
echo To reduce project size further:
echo 1. Run 'flutter clean' before committing
echo 2. Don't commit build/ directories
echo 3. Use .gitignore to exclude build files
echo 4. Remove unused assets and dependencies
echo.
pause
