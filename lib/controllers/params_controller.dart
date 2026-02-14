import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
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
  final assessment = Rxn<WaterQualityAssessment>();

  late Site site;
  late String paramName;

  final _historyCache = <String, List<FlSpot>>{};

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      site = Get.arguments['site'];
      paramName = Get.arguments['paramName'];

      // Load initial data
      loadParameters();

      // Listen for data updates from SitesController (in case they arrive late)
      final sitesController = Get.find<SitesController>();
      ever(sitesController.siteRawData, (_) => loadParameters());
    }
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
      String op = "";
      if (category == "PHYSICAL & CHEMICAL") {
        op = "physicalChemical";
      } else if (category == "HEALTH & AESTHETIC") {
        op = "HealthAesthetic";
      } else if (category == "METALS") {
        op = "Metals";
      } else if (category == "IONIC FEATURES") {
        op = "IonicFeatures";
      }

      Map<String, dynamic> displayData = Map<String, dynamic>.from(
        rawData[op] ?? {},
      );

      // Apply unit conversions consistently for all categories (from µg/L to mg/L for specific metals)
      const metalsToConvert = [
        'Iron',
        'Lead',
        'Flouride',
        'Fluoride',
        'Arsenic',
        'Manganese',
      ];

      for (var metal in metalsToConvert) {
        if (displayData.containsKey(metal)) {
          final val = double.tryParse(displayData[metal]?.toString() ?? "");
          if (val != null) {
            displayData[metal] = val / 1000.0;
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
    } catch (e) {
      print("Error loading parameters: $e");
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

      if ([
        "chlorophyll",
        "CO2",
        "H2S",
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

      final double? val = double.tryParse(value?.toString() ?? "");
      if (val != null) {
        final status =
            WaterQualityCalculator.bisStandards[key]?.getStatus(val) ??
            WaterQualityStatus.good;

        list.add(
          ParameterData(
            name: _formatDisplayName(key),
            key: key,
            value: "${val.toStringAsFixed(2)} ${_getUnit(key)}",
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
    if (_historyCache.containsKey(cacheKey)) {
      historyPoints.value = _historyCache[cacheKey]!;
      isHistoryLoading.value = false;
      return;
    }

    isHistoryLoading.value = true;
    historyPoints.clear();
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

          final reversedList = dataList.reversed.toList();

          for (int i = 0; i < reversedList.length; i++) {
            final val = double.tryParse(
              reversedList[i][paramKey]?.toString() ?? "",
            );
            if (val != null) {
              points.add(FlSpot(i.toDouble(), val));
            }
          }
          _historyCache[cacheKey] = points;
          historyPoints.value = points;
        }
      }
    } catch (e) {
      print("Error fetching history for $paramKey: $e");
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
        return "Nitrate";
      case "Manganese":
        return "Manganese";
      case "Arsenic":
        return "Arsenic";
      default:
        return key.replaceAll("_", " ");
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
}
