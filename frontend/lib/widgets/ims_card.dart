import 'package:flutter/material.dart';
import 'app_theme.dart';

class ImsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const ImsCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double paddingValue = 20.0;

    if (screenWidth < 400) {
      paddingValue = 12.0;
    } else if (screenWidth < 600) {
      paddingValue = 16.0;
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: padding ?? EdgeInsets.all(paddingValue),
          child: child,
        ),
      ),
    );
  }
}
