import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Border? border;
  final List<Color>? gradientColors;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 12.0,
    this.border,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors ??
                  [
                    Colors.white.withAlpha(20), // Translucent white
                    Colors.white.withAlpha(5),  // Near transparent white
                  ],
            ),
            border: border ??
                Border.all(
                  color: Colors.white.withAlpha(30), // Thin metallic edge
                  width: 1.5,
                ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
