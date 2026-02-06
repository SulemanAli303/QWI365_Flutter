import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 1.0});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icon_transparent.png',
          height: 80 * size,
          width: 80 * size,
          fit: BoxFit.contain,
        ),

        Image.asset(
          'assets/text_logo.png',
          height: 40 * size,
          width: 150 * size,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
