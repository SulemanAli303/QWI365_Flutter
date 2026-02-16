import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:water365/utils/app_colors.dart';

class CustomFullLoader extends StatefulWidget {
  const CustomFullLoader({super.key});

  @override
  State<CustomFullLoader> createState() => _CustomFullLoaderState();
}

class _CustomFullLoaderState extends State<CustomFullLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: RotationTransition(
          turns: _controller,
          child: SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              children: List.generate(8, (index) {
                final double angle = index * 2 * math.pi / 8;
                final double size = 6.0 + (index * 1.5);

                return Align(
                  alignment: Alignment(math.cos(angle), math.sin(angle)),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
