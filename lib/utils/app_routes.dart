import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/sites_screen.dart';
import '../screens/graphs_screen.dart';
import '../screens/recipes_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/forgot_password_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String sites = '/sites';
  static const String graphs = '/graphs';
  static const String recipes = '/recipes';
  static const String settings = '/settings';
  static const String forgot = '/forgot';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case sites:
        return MaterialPageRoute(builder: (_) => const SitesScreen());
      case graphs:
        return MaterialPageRoute(builder: (_) => const GraphsScreen());
      case recipes:
        return MaterialPageRoute(builder: (_) => const RecipesScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case forgot:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
