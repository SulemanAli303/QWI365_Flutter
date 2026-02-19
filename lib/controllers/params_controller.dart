import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:water365/controllers/sites_controller.dart';
import 'package:water365/models/site.dart';
import 'package:water365/utils/water_quality_calculator.dart';

class ParameterData {
  final String name;
  final String key; // Added to identify parameter
  final String value;
  final double numericValue; // Added for graphing
  final WaterQualityStatus status;

  ParameterData({
    required this.name,
    required this.key,
    required this.value,
    required this.numericValue,
    required this.status,
  });
}

class ParamsController extends GetxController {
  final isLoading = false.obs;
  final isHistoryLoading = false.obs;
  final parameters = <ParameterData>[].obs;
  final historyPoints = <FlSpot>[].obs;
  final historyDates = <String>[].obs; // Store formatted dates for X-axis
  final assessment = Rxn<WaterQualityAssessment>();

  // Chart zoom state
  final minX = 0.0.obs;
  final maxX = 0.0.obs;
  final minY = 0.0.obs;
  final maxY = 0.0.obs;

  late Site site;
  late String paramName;

  final _historyCache = <String, List<FlSpot>>{};
  final _historyDatesCache = <String, List<String>>{}; // Cache dates too

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      site = Get.arguments['site'];
      paramName = Get.arguments['paramName'];
      print(
        "Initializing ParamsController [${site.siteName} - $paramName] Tag: ${site.siteName}_$paramName",
      );
      // Load initial data
      loadParameters();

      // Listen for data updates from SitesController (in case they arrive late)
      final sitesController = Get.find<SitesController>();
      _worker = ever(sitesController.siteRawData, (_) {
        print("siteRawData updated, reloading for ${site.siteName}");
        loadParameters();
      });
    }
  }

  late Worker _worker;

  @override
  void onClose() {
    if (Get.arguments != null) {
      _worker.dispose();
    }
    super.onClose();
  }

  void loadParameters() {
    // We remove the isLoading toggle here because processing local data is instant.
    // This avoids unnecessary full-screen flickers.
    try {
      final sitesController = Get.find<SitesController>();
      final rawData = sitesController.siteRawData[site.siteName];
      if (rawData == null) {
        // If data hasn't arrived yet, we don't clear, we just wait.
        // The screen will show "No records found" or we can rely on SitesController's loading state.
        return;
      }

      final category = paramName.toUpperCase();
      Map<String, dynamic> displayData = {};

      print("loadParameters for site: ${site.siteName}, category: $category");

      if (category == "HEALTH & AESTHETIC") {
        // MERGE LOGIC matching iOS Params.swift
        final healthRaw = rawData["HealthAestheticNew"] ?? {};
        final physicalRaw = rawData["physicalChemicalNew"] ?? {};
        final metalsRaw = rawData["Metals"] ?? {};

        print(
          "Health/Aesthetic Merge - Health keys: ${healthRaw.keys.length}, Phys keys: ${physicalRaw.keys.length}, Metals keys: ${metalsRaw.keys.length}",
        );

        displayData = {
          // From Physical/Chemical API
          'pH': physicalRaw['pH'],
          'EC': physicalRaw['EC'],
          'TDS': physicalRaw['TDS'],
          'TSS': physicalRaw['TSS'],
          'Total_Alkalinity': physicalRaw['Total_Alkalinity'],
          'Turbidity': physicalRaw['Turbidity'],
          'Temperature': physicalRaw['Temperature'],
          'Total_Hardness': physicalRaw['Total_Hardness'],
          'ORPe': physicalRaw['ORPe'],
          'DO': physicalRaw['DO'],

          // From Health Aesthetic API
          'Flouride': healthRaw['Flouride'],
          'Residual_Chlorine': healthRaw['Residual_Chlorine'],
          'combinedChlorine':
              healthRaw['Free_Chlorine'], // Mapping from iOS code
          'E_Coli': healthRaw['E_Coli'],
          'Total_Coliforms': healthRaw['Total_Coliforms'],
          'Fecal_Coliforms': healthRaw['Fecal_Coliforms'],

          // From Metals API
          'Iron': metalsRaw['Iron'],
          'Lead': metalsRaw['Lead'],
          'Arsenic': metalsRaw['Arsenic'],
        };
      } else {
        String op = "";
        if (category == "PHYSICAL & CHEMICAL") {
          op = "physicalChemicalNew";
        } else if (category == "METALS") {
          op = "Metals";
        } else if (category == "IONIC FEATURES") {
          op = "IonicFeatures";
        }
        print(
          "Processing parameters for category: $category using operation: $op, rawData[op] keys: ${rawData[op]?.keys.length ?? 0}",
        );
        displayData = Map<String, dynamic>.from(rawData[op] ?? {});
      }

      // Apply unit conversions consistently for all categories (from µg/L to mg/L or similar)
      const paramsToConvert = [
        'Iron',
        'Lead',
        'Flouride',
        'Fluoride',
        'Arsenic',
        'Manganese',
        'TDS', // Convert TDS from mg/L to g/L parity
      ];

      for (var param in paramsToConvert) {
        if (displayData.containsKey(param)) {
          final val = double.tryParse(displayData[param]?.toString() ?? "");
          if (val != null) {
            displayData[param] = val / 1000.0;
          }
        }
      }

      // Add calculated Color if TSS and Turbidity exist (usually in HealthAesthetic)
      if (displayData.containsKey('TSS') &&
          displayData.containsKey('Turbidity')) {
        final tss =
            double.tryParse(displayData['TSS']?.toString() ?? "0") ?? 0.0;
        final turb =
            double.tryParse(displayData['Turbidity']?.toString() ?? "0") ?? 0.0;
        displayData['Color'] = WaterQualityCalculator.calculateColor(
          tss: tss,
          turbidity: turb,
        );
      }

      _processData(displayData);
      print("Parameters loaded: ${parameters.length} items");
    } catch (e) {
      debugPrint("Error loading parameters: $e");
    }
  }

  void _processData(Map<String, dynamic> data) {
    final List<ParameterData> list = [];
    final Map<String, double> assessmentMap = {};

    data.forEach((key, value) {
      if (key == "Site_Name" ||
          key == "Last_Update" ||
          key == "Latitude" ||
          key == "Longitude" ||
          key == "siteID") {
        return;
      }

      if (paramName == "Ionic Features" || paramName == "METALS") {
        if ([
          "HCO3",
          "Mg",
          "Strontium",
          "Vanadium",
          "Cadmium",
          "Cobalt",
          "Nickel",
          "Silica",
          "Zinc",
        ].contains(key)) {
          return;
        }
      } else {
        if (["chlorophyll", "CO2", "H2S"].contains(key)) {
          return;
        }
      }

      final double? val = double.tryParse(value?.toString() ?? "");
      if (val != null) {
        final status =
            WaterQualityCalculator.bisStandards[key]?.getStatus(val) ??
            WaterQualityStatus.good;

        list.add(
          ParameterData(
            name: _formatDisplayName(key),
            key: key,
            value: "${_formatValue(val, key)} ${_getUnit(key)}",
            numericValue: val,
            status: status,
          ),
        );
        assessmentMap[key] = val;
      }
    });

    list.sort((a, b) => a.name.compareTo(b.name));
    parameters.value = list;

    assessment.value = WaterQualityCalculator.calculateConformance(
      assessmentMap,
    );
  }

  Future<void> fetchHistory(String paramKey) async {
    final cacheKey = "${site.siteName}_$paramKey";

    // Use cached data if available to avoid "itna loader"
    if (_historyCache.containsKey(cacheKey) &&
        _historyDatesCache.containsKey(cacheKey)) {
      historyPoints.value = _historyCache[cacheKey]!;
      historyDates.value = _historyDatesCache[cacheKey]!;

      // Initialize chart zoom ranges for cached data
      if (historyPoints.isNotEmpty) {
        minX.value = historyPoints.first.x;
        maxX.value = historyPoints.last.x;
        final yValues = historyPoints.map((e) => e.y).toList();
        minY.value = yValues.reduce((a, b) => a < b ? a : b) * 0.9;
        maxY.value = yValues.reduce((a, b) => a > b ? a : b) * 1.1;
      }

      isHistoryLoading.value = false;
      return;
    }

    isHistoryLoading.value = true;
    historyPoints.clear();
    historyDates.clear();
    try {
      final sitesController = Get.find<SitesController>();
      final prefs = await sitesController.apiService.getPrefs();
      final username = prefs.getString('username');
      if (username == null) return;

      final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

      final body =
          '''
<HistoricalData xmlns="http://tempuri.org/">
  <UserName>$username</UserName>
  <SiteName>${site.siteName}</SiteName>
  <FromDate>$dateStr</FromDate>
  <ToDate>$dateStr</ToDate>
  <param>$paramKey</param>
</HistoricalData>''';

      final response = await sitesController.apiService.soapRequest(
        operation: "HistoricalData",
        body: body,
      );

      if (response != null) {
        final jsonStr = sitesController.apiService.parseSoapResponse(
          response,
          "HistoricalData",
        );
        if (jsonStr != "[]") {
          final List<dynamic> dataList = json.decode(jsonStr);
          final List<FlSpot> points = [];
          final List<String> dates = [];

          final reversedList = dataList.reversed.toList();

          for (int i = 0; i < reversedList.length; i++) {
            final val = double.tryParse(
              reversedList[i][paramKey]?.toString() ?? "",
            );
            if (val != null) {
              points.add(FlSpot(i.toDouble(), val));

              // Try to get timestamp from data with multiple fallbacks
              String timeLabel = "";
              final item = reversedList[i];
              String? rawDate =
                  item['Last_Update']?.toString() ??
                  item['Date']?.toString() ??
                  item['date']?.toString() ??
                  item['dat']?.toString() ??
                  item['Dat']?.toString() ??
                  item['DAT']?.toString() ??
                  item['DateTime']?.toString() ??
                  item['Time']?.toString() ??
                  item['time']?.toString();

              if (rawDate != null && rawDate.isNotEmpty) {
                DateTime? dt;

                // Try several parsing formats
                final formats = [
                  null, // ISO 8601
                  'dd/MM/yyyy HH:mm:ss',
                  'dd/MM/yyyy HH:mm',
                  'dd/MM/yyyy h:mm a', // Added common format
                  'dd-MM-yyyy HH:mm:ss',
                  'dd-MM-yyyy HH:mm',
                  'dd/MMM/yyyy HH:mm:ss',
                  'dd-MMM-yyyy HH:mm',
                  'yyyy-MM-dd HH:mm:ss',
                ];

                for (var format in formats) {
                  try {
                    if (format == null) {
                      dt = DateTime.parse(rawDate);
                    } else {
                      dt = DateFormat(format).parse(rawDate);
                    }
                    break; // Removed null check to satisfy lint
                  } catch (_) {}
                }

                if (dt != null) {
                  timeLabel = DateFormat('H:mm').format(dt);
                } else {
                  // CRITICAL FALLBACK: If parsing failed, try to find a time pattern (XX:XX) in the raw string
                  final timeRegex = RegExp(r'(\d{1,2}:\d{2})');
                  final match = timeRegex.firstMatch(rawDate);
                  if (match != null) {
                    timeLabel = match.group(1)!;
                    // Remove leading zero if needed to match "0:00" style instead of "00:00"
                    if (timeLabel.startsWith('0') && timeLabel.length > 4) {
                      timeLabel = timeLabel.substring(1);
                    }
                  } else {
                    timeLabel = rawDate.split(' ').last;
                    if (timeLabel.length > 5)
                      timeLabel = timeLabel.substring(0, 5);
                  }
                }
              }

              // If it's still empty or just a number, we try a different key
              if (timeLabel.isEmpty || RegExp(r'^\d+$').hasMatch(timeLabel)) {
                // Check every key in the item for a ':' which usually indicates time
                for (var key in item.keys) {
                  final valStr = item[key].toString();
                  if (valStr.contains(':')) {
                    final timeRegex = RegExp(r'(\d{1,2}:\d{2})');
                    final match = timeRegex.firstMatch(valStr);
                    if (match != null) {
                      timeLabel = match.group(1)!;
                      break;
                    }
                  }
                }
              }

              // Final desperate fallback if nothing worked
              if (timeLabel.isEmpty) {
                timeLabel = "0:00"; // Default instead of index
              }
              dates.add(timeLabel);
            }
          }
          _historyCache[cacheKey] = points;
          _historyDatesCache[cacheKey] = dates;
          historyPoints.value = points;
          historyDates.value = dates;

          // Initialize chart zoom ranges
          if (points.isNotEmpty) {
            minX.value = points.first.x;
            maxX.value = points.last.x;
            final yValues = points.map((e) => e.y).toList();
            minY.value = yValues.reduce((a, b) => a < b ? a : b) * 0.9;
            maxY.value = yValues.reduce((a, b) => a > b ? a : b) * 1.1;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching history for $paramKey: $e");
    } finally {
      isHistoryLoading.value = false;
    }
  }

  String _formatDisplayName(String key) {
    switch (key) {
      case "pH":
        return "pH";
      case "EC":
        return "EC";
      case "TDS":
        return "Total Dissolved Solids";
      case "DO":
        return "Dissolved Oxygen";
      case "Total_Coliforms":
        return "Total Coliforms(Good & Bad)";
      case "E_Coli":
        return "E-Coli";
      case "Fecal_Coliforms":
        return "Fecal Coliforms";
      case "Residual_Chlorine":
        return "Residual Chlorine";
      case "combinedChlorine":
        return "Combined Chlorine";
      case "Flouride":
        return "Fluoride";
      case "No3":
        return "NO\u{2083}";
      case "Manganese":
        return "Manganese";
      case "Arsenic":
        return "Arsenic";
      case "CO2":
        return "CO\u{2082}";
      case "H2S":
        return "H\u{2082}S";
      case "NH4":
        return "NH\u{2084}";
      case "HCO3":
        return "HCO\u{2083}";
      case "ORPe":
      case "ORP":
        return "ORP";
      default:
        return key.replaceAll("_", " ");
    }
  }

  void resetZoom() {
    if (historyPoints.isNotEmpty) {
      minX.value = historyPoints.first.x;
      maxX.value = historyPoints.last.x;
      final yValues = historyPoints.map((e) => e.y).toList();
      minY.value = yValues.reduce((a, b) => a < b ? a : b) * 0.9;
      maxY.value = yValues.reduce((a, b) => a > b ? a : b) * 1.1;
    }
  }

  String _getUnit(String key) {
    if (key == "EC") return "dS/m";
    if (key == "Temperature") return "°C";
    if (key == "Hardness" ||
        key == "Alkalinity" ||
        key == "TSS" ||
        key == "DO" ||
        key == "COD" ||
        key == "BOD5" ||
        key == "CO2" ||
        key == "Residual_Chlorine" ||
        key == "combinedChlorine" ||
        key == "H2S" ||
        key == "Iron" ||
        key == "Lead" ||
        key == "Fluoride" ||
        key == "Flouride" ||
        key == "Arsenic" ||
        key == "Manganese" ||
        key == "Ca" ||
        key == "Mg" ||
        key == "Na" ||
        key == "Cl" ||
        key == "No3") {
      return "mg/L";
    }
    if (key == "TDS") return "g/L";
    if (key == "ORPe" || key == "ORP") return "mV";
    if (key == "Turbidity") return "NTU";
    if (key == "E_Coli" || key == "Total_Coliforms") return "MPN/100ml";
    if (key == "Color") return "PCU";
    if (key == "chlorophyll") return "µg/L";
    if (key == "Fecal_Coliforms") return "CFU/100ml";
    return "";
  }

  String _formatValue(double val, String key) {
    // The user wants exactly 2 decimal places for all values now.
    // Standard rounding is used (e.g., 1.107 -> 1.11).
    return val.toStringAsFixed(2);
  }
}
