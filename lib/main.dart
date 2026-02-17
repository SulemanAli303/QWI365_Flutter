import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:water365/utils/app_colors.dart';
import 'package:water365/feature/splash_screen.dart';
import 'package:water365/feature/login_screen.dart';
import 'package:water365/feature/home_screen.dart';
import 'package:water365/feature/sites_screen.dart';
import 'package:water365/feature/params_screen.dart';
import 'package:water365/feature/about_screen.dart';
import 'package:water365/feature/settings_screen.dart';
import 'package:water365/feature/forgot_screen.dart';


class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Water 365',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primaryOrange,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor:
              AppColors.backgroundColor, // Screenshot shows dark app bars
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SplashScreen(),
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/sites', page: () => const SitesScreen()),
        GetPage(name: '/params', page: () => const ParamsScreen()),
        GetPage(name: '/about', page: () => const AboutScreen()),
        GetPage(name: '/settings', page: () => const SettingsScreen()),
        GetPage(name: '/forgot', page: () => const ForgotScreen()),
      ],
    );
  }
}
