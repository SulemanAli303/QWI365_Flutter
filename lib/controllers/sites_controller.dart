import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water365/models/site.dart';
import 'package:water365/services/api_service.dart';

class SitesController extends GetxController {
  final apiService = ApiService();
  final sites = <Site>[].obs;
  final selectedIndex = 0.obs;
  final isLoading = false.obs;

  final categories = [
    "PHYSICAL & CHEMICAL",
    "HEALTH & AESTHETIC",
    "METALS",
    "IONIC FEATURES",
  ];

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      if (Get.arguments['allSites'] != null) {
        sites.value = Get.arguments['allSites'];
      }
      if (Get.arguments['site'] != null) {
        final site = Get.arguments['site'] as Site;
        final index = sites.indexWhere((s) => s.siteName == site.siteName);
        if (index != -1) {
          selectedIndex.value = index;
        }
      }
    }

    if (sites.isEmpty) {
      fetchSites();
    }
  }

  Future<void> fetchSites() async {
    isLoading.value = true;
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

          // Set default index if needed
          if (sites.isNotEmpty) {
            selectedIndex.value = 0;
            // Check for default site from settings
            final defSite = prefs.getString('defSite');
            if (defSite != null && defSite != "none") {
              final index = sites.indexWhere((s) => s.siteName == defSite);
              if (index != -1) selectedIndex.value = index;
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching sites in SitesController: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Site? get selectedSite =>
      sites.isNotEmpty ? sites[selectedIndex.value] : null;

  void nextSite() {
    if (selectedIndex.value < sites.length - 1) {
      selectedIndex.value++;
    }
  }

  void prevSite() {
    if (selectedIndex.value > 0) {
      selectedIndex.value--;
    }
  }

  void selectSite(int index) {
    if (index >= 0 && index < sites.length) {
      selectedIndex.value = index;
    }
  }
}
