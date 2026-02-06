import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:water365/controllers/home_controller.dart';
import 'package:water365/utils/app_colors.dart';
import 'package:water365/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => controller.toggleMapMode(),
            child: Image.asset('assets/globe.png', height: 25),
          ),
          const SizedBox(width: 30),
          GestureDetector(
            onTap: () {
              Get.toNamed('/settings');
            },
            child: Image.asset('assets/settings_icon.png', height: 25),
          ),
          const SizedBox(width: 30),
          GestureDetector(
            onTap: () => controller.logout(),
            child: Image.asset('assets/logout.png', height: 25),
          ),
          const SizedBox(width: 30),
        ],
      ),
      drawer: const AppDrawer(),
      body: Obx(
        () => Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 2,
              ),
              onMapCreated: controller.onMapCreated,
              markers: controller.markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapType: controller.mapType.value,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            if (controller.isLoading.value)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryOrange,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
