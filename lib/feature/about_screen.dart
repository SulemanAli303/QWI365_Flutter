import 'package:flutter/material.dart';
import 'package:water365/utils/app_colors.dart';
import 'package:water365/widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(title: const Text("ABOUT"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const AppLogo(),
            const SizedBox(height: 40),
            const Text(
              "Water 365 is a comprehensive water quality monitoring solution. "
              "Our application provides real-time data on various physical, chemical, "
              "and biological parameters of water sites across the region.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 50),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),
            const Text(
              "Developed by Realtech Systems",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Text(
              "© 2026 All rights reserved",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
