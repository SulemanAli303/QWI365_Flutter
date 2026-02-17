import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water365/models/site.dart';
import 'package:water365/services/api_service.dart';
import 'package:water365/utils/app_colors.dart';

class HomeController extends GetxController {
  final apiService = ApiService();
  final sites = <Site>[].obs;
  final isLoading = false.obs;
  final markers = <Marker>{}.obs;
  final mapType = MapType.hybrid.obs;

  Timer? _refreshTimer;
  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    fetchSites();
    _startTimer();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('mapMode') ?? "sat";
    mapType.value = (mode == "sat") ? MapType.hybrid : MapType.normal;
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void _startTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 90), (timer) {
      fetchSites(isRefresh: true);
    });
  }

  Future<void> fetchSites({bool isRefresh = false}) async {
    if (!isRefresh) isLoading.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username == null) return;

      final body =
          '<Sites xmlns="http://tempuri.org/"><UserName>$username</UserName></Sites>';
      final responseBody = await apiService.soapRequest(
        operation: "Sites",
        body: body,
      );

      if (responseBody != null) {
        final result = apiService.parseSoapResponse(responseBody, "Sites");
        if (result != "[]") {
          final List<dynamic> jsonList = json.decode(result);
          sites.value = jsonList.map((j) => Site.fromJson(j)).toList();
          _updateMarkers();
        }
      }
    } catch (e) {
     debugPrint("Error fetching sites: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _updateMarkers() {
    final newMarkers = sites.map((site) {
      return Marker(
        markerId: MarkerId(site.siteName),
        position: site.coordinate,
        infoWindow: InfoWindow(
          title: site.siteName,
          snippet: site.formattedLastUpdate,
          onTap: () {
            Get.toNamed(
              '/sites',
              arguments: {'site': site, 'allSites': sites.toList()},
            );
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }).toSet();
    markers.assignAll(newMarkers);

    if (sites.isNotEmpty && mapController != null) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (sites.isEmpty || mapController == null) return;

    double minLat = sites.first.latitude;
    double maxLat = sites.first.latitude;
    double minLng = sites.first.longitude;
    double maxLng = sites.first.longitude;

    for (var site in sites) {
      if (site.latitude < minLat) minLat = site.latitude;
      if (site.latitude > maxLat) maxLat = site.latitude;
      if (site.longitude < minLng) minLng = site.longitude;
      if (site.longitude > maxLng) maxLng = site.longitude;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0,
      ),
    );
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (sites.isNotEmpty) {
      _fitBounds();
    }
  }

  void toggleMapMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mapType.value == MapType.hybrid) {
      mapType.value = MapType.normal;
      await prefs.setString('mapMode', 'street');
    } else {
      mapType.value = MapType.hybrid;
      await prefs.setString('mapMode', 'sat');
    }
  }

  void logout() async {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.logoutBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 25),
              const Text(
                "Attention",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Do you want to logout?",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 25),
              const Divider(color: Colors.white24, height: 1),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          Get.offAllNamed('/login');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: const Center(
                            child: Text(
                              "Yes",
                              style: TextStyle(
                                color: Color(0xFFFF453A), // Red
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(color: Colors.white24, width: 1),
                    Expanded(
                      child: InkWell(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: const Center(
                            child: Text(
                              "No",
                              style: TextStyle(
                                color: Color(0xFF0A84FF), // Blue
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
