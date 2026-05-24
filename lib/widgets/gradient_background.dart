import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;

  const GradientBackground({
    Key? key,
    required this.child,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // width/height: infinity makes the gradient fill the parent (typically the
    // Scaffold body) instead of shrinking to the child's size. Without this,
    // short scroll content leaves the Scaffold's dark background visible below.
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
      ),
      child: child,
    );
  }
}
