import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water365/controllers/home_controller.dart';
import 'package:water365/utils/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundColor,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 60),
          _buildDrawerItem(
            icon: 'assets/account.png',
            title: "WATER 365",
            onTap: () {
              Get.back();
              // Try to find HomeController to pass current sites
              List? sites;
              try {
                final homeController = Get.find<HomeController>();
                sites = homeController.sites.toList();
              } catch (_) {}

              Get.toNamed('/settings', arguments: {'sites': sites});
            },
          ),
          const SizedBox(height: 10),
          _buildDrawerItem(
            icon: 'assets/site.png',
            title: "SITES",
            onTap: () {
              Get.back();
              // Try to find HomeController to pass current sites
              List? sites;
              try {
                final homeController = Get.find<HomeController>();
                sites = homeController.sites.toList();
              } catch (_) {}

              Get.toNamed('/sites', arguments: {'allSites': sites});
            },
          ),
          const SizedBox(height: 10),
          _buildDrawerItem(
            icon: 'assets/about_icon.png',
            title: "ABOUT",
            onTap: () {
              Get.back();
              Get.toNamed('/about');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return ListTile(
      leading: Image.asset(
        icon,
        color: iconColor,
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.white),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
    );
  }
}
