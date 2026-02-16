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
                  _buildRiskTiles(controller),
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
                            color: Colors.black,
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
                      return controller.sites.map((site) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            site.siteName,
                            style: const TextStyle(
                              color: Colors.black,
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
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black..withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(5, 5),
            ),
          ],
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

  Widget _buildRiskTiles(SitesController controller) {
    return Obx(() {
      final risk = controller.selectedRisk;
      if (risk == null) {
        if (controller.isDataLoading.value) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            ),
          );
        }
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildRiskTile(
                    "Water Portability",
                    risk.portabilityPercentage,
                    _getRiskColor(risk.overallRisk),
                    isPortability: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildRiskTile(
                    "Water Contamination",
                    risk.contaminationPercentage,
                    _getRiskColor(risk.overallRisk),
                    isContamination: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Color _getRiskColor(String risk) {
    if (risk == "RED") return const Color(0xFFFF0000);
    if (risk == "YELLOW") return const Color(0xFFEFFF00);
    return const Color(0xFF33D940);
  }

  void _showContaminationInfo() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Water Contamination Risk",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Water Contamination Risk indicates the level of pollutants, microorganisms, and harmful chemicals detected. Higher percentages suggest a higher presence of substances that may compromise water safety.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 5,
              top: 5,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 25),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPortabilityInfo() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Water Portability",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Water potability is in absence any metal contamination,  microorgnisms and minor passing of harmless physical parameters. Higher the percentage better is potability.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 5,
              top: 5,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 25),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskTile(
    String title,
    double percentage,
    Color color, {
    bool isContamination = false,
    bool isPortability = false,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white..withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          if (isContamination)
            Column(
              children: [
                Text(
                  "Water Contamination",
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Risk",
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _showContaminationInfo,
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.black,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else if (isPortability)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Water Portability",
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _showPortabilityInfo,
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.black,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              title,
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
          const SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 65,
                height: 65,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.white12,
                  color: color,
                  strokeWidth: 7,
                ),
              ),
              Text(
                "${percentage.round()}%",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 15,
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
