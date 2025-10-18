# UniFood App Icon

## Overview
This directory contains the app icon design and implementation for UniFood - University Canteen Management System.

## Files
- `assets/app_icon.svg` - Vector version of the app icon
- `assets/app_icon_description.md` - Detailed design specifications
- `lib/widgets/app_logo.dart` - Flutter widget for consistent branding
- `generate_app_icon.dart` - Helper script for icon generation

## Design
The app icon features:
- **Gradient Background**: Green to Orange gradient
- **Restaurant Icon**: Food service symbol in center
- **Modern Design**: Clean, professional appearance
- **University Theme**: Suitable for educational environment

## Usage

### In Flutter App
```dart
import '../widgets/app_logo.dart';

// Basic logo
AppLogo(size: 100)

// Logo with text
AppLogoWithText(logoSize: 60, textSize: 24)

// Minimal logo
AppLogoMinimal(size: 50)
```

### For App Stores
1. Use the SVG file as a template
2. Export to PNG at 512x512 resolution
3. Ensure high contrast and clarity
4. Test at various sizes

## Color Palette
- Primary Green: #4CAF50
- Secondary Orange: #FF9800
- White: #FFFFFF
- Light Green: #81C784
- Light Orange: #FFB74D

## Implementation
The AppLogo widget is already integrated into:
- Profile screen
- Help screen
- Can be used anywhere in the app

## Branding Guidelines
- Always use the gradient colors
- Maintain aspect ratio
- Ensure readability at small sizes
- Keep consistent with university theme
