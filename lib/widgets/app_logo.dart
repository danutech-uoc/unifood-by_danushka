import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? primaryColor;
  final Color? secondaryColor;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = true,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? Colors.green.shade600;
    final secondary = secondaryColor ?? Colors.orange.shade400;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _LogoBackgroundPainter(primary, secondary),
            ),
          ),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(size * 0.15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(size * 0.1),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: size * 0.4,
                  ),
                ),
                
                if (showText) ...[
                  SizedBox(height: size * 0.05),
                  Text(
                    'UniFood',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _LogoBackgroundPainter(this.primaryColor, this.secondaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    final center = Offset(size.width / 2, size.height / 2);
    
    // Top-left circle
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      size.width * 0.1,
      paint,
    );
    
    // Bottom-right circle
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.8),
      size.width * 0.08,
      paint,
    );
    
    // Center circle
    canvas.drawCircle(
      center,
      size.width * 0.05,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Alternative logo with different style
class AppLogoMinimal extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogoMinimal({
    super.key,
    this.size = 50,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Colors.green.shade600;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: logoColor,
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: logoColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.restaurant,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

// Logo with text variant
class AppLogoWithText extends StatelessWidget {
  final double logoSize;
  final double textSize;
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool horizontal;

  const AppLogoWithText({
    super.key,
    this.logoSize = 60,
    this.textSize = 24,
    this.primaryColor,
    this.secondaryColor,
    this.horizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? Colors.green.shade600;
    final secondary = secondaryColor ?? Colors.orange.shade400;

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogo(
            size: logoSize,
            showText: false,
            primaryColor: primary,
            secondaryColor: secondary,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'UniFood',
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  color: primary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'University Canteen',
                style: TextStyle(
                  fontSize: textSize * 0.6,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogo(
            size: logoSize,
            showText: false,
            primaryColor: primary,
            secondaryColor: secondary,
          ),
          const SizedBox(height: 12),
          Text(
            'UniFood',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: primary,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'University Canteen',
            style: TextStyle(
              fontSize: textSize * 0.6,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }
}
