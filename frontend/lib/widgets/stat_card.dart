import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = const Color(0xFF18332B),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double paddingValue = 20.0;
    double iconSize = 32.0;
    double valueFontSize = 24.0;
    double titleFontSize = 16.0;

    if (screenWidth < 400) {
      paddingValue = 12.0;
      iconSize = 24.0;
      valueFontSize = 18.0;
      titleFontSize = 12.0;
    } else if (screenWidth < 600) {
      paddingValue = 16.0;
      iconSize = 28.0;
      valueFontSize = 20.0;
      titleFontSize = 14.0;
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(paddingValue),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: iconSize),
              SizedBox(height: paddingValue * 0.8),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: paddingValue * 0.4),
              Text(
                title,
                style: TextStyle(fontSize: titleFontSize, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
