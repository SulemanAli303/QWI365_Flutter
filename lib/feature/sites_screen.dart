import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:water365/controllers/sites_controller.dart';
import 'package:water365/utils/app_colors.dart';

class SitesScreen extends StatelessWidget {
  const SitesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SitesController());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text("Sites"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryOrange),
          );
        }

        if (controller.sites.isEmpty) {
          return const Center(
            child: Text(
              "No sites available",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 10),
            _buildSiteSelector(controller),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                children: [
                  _buildDateDisplay(controller),
                  _buildMapPreview(controller),
                  const SizedBox(height: 15),
                  ...controller.categories.asMap().entries.map((entry) {
                    return _buildCategoryItem(entry.value, entry.key);
                  }),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSiteSelector(SitesController controller) {
    const Color silverColor = AppColors.lightGrey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Left Arrow Button
          Obx(
            () => GestureDetector(
              onTap: controller.selectedIndex.value > 0
                  ? controller.prevSite
                  : null,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: silverColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/left.png',
                    width: 20,
                    height: 20,
                    color: controller.selectedIndex.value > 0
                        ? Colors.black
                        : Colors.black26,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Center Site Selector / Dropdown
          Expanded(
            child: Obx(
              () => Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: silverColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: controller.selectedIndex.value,
                    dropdownColor: silverColor,
                    isExpanded: true,
                    icon: Image.asset(
                      'assets/down.png',
                      width: 15,
                      height: 15,
                      color: Colors.black,
                    ),
                    items: controller.sites.asMap().entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(
                          entry.value.siteName,
                          style: const TextStyle(
                            color: Colors.black, // Items in list are black
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        controller.selectSite(val);
                      }
                    },
                    selectedItemBuilder: (context) {
                      // The text on the tile itself is WHITE in the screenshot
                      return controller.sites.map((site) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            site.siteName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Right Arrow Button
          Obx(
            () => GestureDetector(
              onTap:
                  controller.selectedIndex.value < controller.sites.length - 1
                  ? controller.nextSite
                  : null,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: silverColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/right.png',
                    width: 20,
                    height: 20,
                    color:
                        controller.selectedIndex.value <
                            controller.sites.length - 1
                        ? Colors.black
                        : Colors.black26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDisplay(SitesController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Obx(
        () => Text(
          controller.selectedSite?.formattedLastUpdate ?? "N/A",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildMapPreview(SitesController controller) {
    return Obx(() {
      final site = controller.selectedSite;
      if (site == null) return const SizedBox(height: 180);

      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: GoogleMap(
          key: ValueKey(site.siteName),
          initialCameraPosition: CameraPosition(
            target: site.coordinate,
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId(site.siteName),
              position: site.coordinate,
            ),
          },
          liteModeEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
        ),
      );
    });
  }

  Widget _buildCategoryItem(String title, int index) {
    final icons = [
      'assets/flask.png',
      'assets/health_drop.png',
      'assets/metal.png',
      'assets/molecule.png',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: ListTile(
        leading: Image.asset(
          icons[index],
          width: 50,
          height: 50,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.science, color: Colors.blue, size: 30),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          final controller = Get.find<SitesController>();
          final site = controller.selectedSite;
          if (site != null) {
            Get.toNamed(
              '/params',
              arguments: {'site': site, 'paramName': title},
            );
          }
        },
      ),
    );
  }
}
