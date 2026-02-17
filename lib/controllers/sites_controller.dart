import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water365/models/site.dart';
import 'package:water365/services/api_service.dart';
import 'package:water365/utils/water_quality_calculator.dart';

class SitesController extends GetxController {
  final apiService = ApiService();
  final sites = <Site>[].obs;
  final selectedIndex = 0.obs;
  final isLoading = false.obs;
  final isDataLoading = false.obs;

  // siteName -> { operationName -> raw data map }
  final siteRawData = <String, Map<String, Map<String, dynamic>>>{}.obs;
  // siteName -> aggregated numeric data map for risk calculation (with conversions)
  final siteRiskData = <String, Map<String, double>>{}.obs;
  // siteName -> RiskResult
  final siteRisks = <String, RiskResult>{}.obs;

  final categories = [
    "PHYSICAL & CHEMICAL",
    "HEALTH & AESTHETIC",
    "METALS",
    // "IONIC FEATURES", // Hidden from UI but data is still fetched
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
      fetchSites().then((_) {
        if (sites.isNotEmpty) {
          fetchAllDataForCurrentSite();
        }
      });
    } else {
      fetchAllDataForCurrentSite();
    }

    // React to site changes
    ever(selectedIndex, (_) {
      fetchAllDataForCurrentSite();
    });
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
         debugPrint("RAW DATA for Sites List -> $result");
          final List<dynamic> jsonList = json.decode(result);
          sites.value = jsonList.map((j) => Site.fromJson(j)).toList();

          // Set default index if needed
          if (sites.isNotEmpty) {
            // Check for default site from settings
            final defSite = prefs.getString('defSite');
            if (defSite != null && defSite != "none") {
              final index = sites.indexWhere((s) => s.siteName == defSite);
              if (index != -1)
                selectedIndex.value = index;
              else
                selectedIndex.value = 0;
            } else {
              selectedIndex.value = 0;
            }
          }
        }
      }
    } catch (e) {
     debugPrint("Error fetching sites in SitesController: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAllDataForCurrentSite() async {
    final site = selectedSite;
    if (site == null) return;

    if (siteRawData.containsKey(site.siteName)) return;

    isDataLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      if (username == null) return;

      final List<Future<String?>> futures = [
        apiService.soapRequest(
          operation: "physicalChemical",
          body:
              '<physicalChemical xmlns="http://tempuri.org/"><UserName>$username</UserName><SiteName>${site.siteName}</SiteName></physicalChemical>',
        ),
        apiService.soapRequest(
          operation: "HealthAesthetic",
          body:
              '<HealthAesthetic xmlns="http://tempuri.org/"><UserName>$username</UserName><SiteName>${site.siteName}</SiteName></HealthAesthetic>',
        ),
        apiService.soapRequest(
          operation: "Metals",
          body:
              '<Metals xmlns="http://tempuri.org/"><UserName>$username</UserName><SiteName>${site.siteName}</SiteName></Metals>',
        ),
      ];

      final results = await Future.wait(futures);
      Map<String, Map<String, dynamic>> rawDataMap = {};
      Map<String, double> numericData = {};

      final ops = ["physicalChemical", "HealthAesthetic", "Metals"];
      for (int i = 0; i < results.length; i++) {
        final res = results[i];
        if (res != null) {
          final jsonStr = apiService.parseSoapResponse(res, ops[i]);
         debugPrint(
            "RAW DATA for Site: ${site.siteName}, Operation: ${ops[i]} -> $jsonStr",
          );
          if (jsonStr != "[]") {
            final List<dynamic> dataList = json.decode(jsonStr);
            if (dataList.isNotEmpty) {
              final Map<String, dynamic> item = Map<String, dynamic>.from(
                dataList[0],
              );
              rawDataMap[ops[i]] = item;

              // Filter out non-numeric and system metadata for risk calculations
              item.forEach((key, value) {
                if (key == "Site_Name" ||
                    key == "Last_Update" ||
                    key == "Latitude" ||
                    key == "Longitude" ||
                    key == "siteID")
                  return;
                final dVal = double.tryParse(value?.toString() ?? "");
                if (dVal != null) {
                  // For risk calculation, apply unit conversions as required
                  double processedVal = dVal;
                  if ([
                    'Iron',
                    'Lead',
                    'Flouride',
                    'Fluoride',
                    'Arsenic',
                    'Manganese',
                  ].contains(key)) {
                    processedVal = dVal / 1000.0;
                  }
                  numericData[key] = processedVal;
                }
              });
            }
          }
        }
      }

      // Special calculation for Color if possible
      if (numericData.containsKey('TSS') &&
          numericData.containsKey('Turbidity')) {
        numericData['Color'] = WaterQualityCalculator.calculateColor(
          tss: numericData['TSS']!,
          turbidity: numericData['Turbidity']!,
        );
      }

      siteRawData[site.siteName] = rawDataMap;
      siteRiskData[site.siteName] = numericData;
      siteRisks[site.siteName] = WaterQualityCalculator.calculateRisk(
        numericData,
      );
    } catch (e) {
     debugPrint("Error fetching all data for site ${site.siteName}: $e");
    } finally {
      isDataLoading.value = false;
    }
  }

  Site? get selectedSite =>
      sites.isNotEmpty ? sites[selectedIndex.value] : null;

  RiskResult? get selectedRisk =>
      selectedSite != null ? siteRisks[selectedSite!.siteName] : null;

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
