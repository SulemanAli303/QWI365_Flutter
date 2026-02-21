import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qwi365/utils/app_colors.dart';
import '../providers/auth_provider.dart';
import '../utils/app_routes.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Drawer(
      child: Container(
        color: AppColors.whiteColor,
        child: Column(
          children: [
            DrawerHeader(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.bgColor,
                    AppColors.bgColor,
                    AppColors.bgColor,
                  ],
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 45, left: 10),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/user.png',
                            height: 50,
                            width: 50,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.whiteColor,
                                ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            authProvider.username ?? 'QWI365',
                            style: const TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    iconPath: 'assets/map_marker_radius.png',
                    title: 'SITES',
                    route: AppRoutes.sites,
                  ),
                  _buildDrawerItem(
                    context: context,
                    iconPath: 'assets/recipe.png',
                    title: 'RECIPES',
                    route: AppRoutes.recipes,
                  ),
                  _buildDrawerItem(
                    context: context,
                    iconPath: 'assets/chart.png',
                    title: 'GRAPHS',
                    route: AppRoutes.graphs,
                  ),
                  _buildDrawerItem(
                    context: context,
                    iconPath: 'assets/valve.png',
                    title: 'VALVES',
                    route:
                        null, // Valve functionality not implemented in Android
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required String iconPath,
    required String title,
    required String? route,
  }) {
    return ListTile(
      leading: Image.asset(
        iconPath,
        width: 24,
        height: 24,
        // errorBuilder: (context, error, stackTrace) =>
        //     const Icon(Icons.error_outline, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
