import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water365/models/site.dart';
import 'package:water365/services/api_service.dart';
import 'package:water365/utils/water_quality_calculator.dart';

class ParameterData {
  final String name;
  final String value;
  final WaterQualityStatus status;

  ParameterData({
    required this.name,
    required this.value,
    required this.status,
  });
}

class ParamsController extends GetxController {
  final apiService = ApiService();
  final isLoading = false.obs;
  final parameters = <ParameterData>[].obs;
  final assessment = Rxn<WaterQualityAssessment>();

  late Site site;
  late String paramName;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      site = Get.arguments['site'];
      paramName = Get.arguments['paramName'];
      fetchParameters();
    }
  }

  Future<void> fetchParameters() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      if (username == null) return;

      // Handle full parity for category switching and aggregation
      final category = paramName.toUpperCase();

      if (category == "HEALTH & AESTHETIC") {
        await _fetchHealthAndAestheticAggregated(username);
      } else {
        String op = "";
        if (category == "PHYSICAL & CHEMICAL") {
          op = "physicalChemical";
        } else if (category == "METALS") {
          op = "Metals";
        } else if (category == "IONIC FEATURES") {
          op = "IonicFeatures";
        }

        if (op.isEmpty) return;

        final body =
            '<$op xmlns="http://tempuri.org/"><UserName>$username</UserName><SiteName>${site.siteName}</SiteName></$op>';
        final responseBody = await apiService.soapRequest(
          operation: op,
          body: body,
        );

        if (responseBody != null) {
          final result = apiService.parseSoapResponse(responseBody, op);
          if (result != "[]") {
            final List<dynamic> jsonList = json.decode(result);
            if (jsonList.isNotEmpty) {
              _processData(jsonList[0]);
            }
          } else {
            parameters.clear();
          }
        }
      }
    } catch (e) {
      print("Error fetching parameters: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchHealthAndAestheticAggregated(String username) async {
    try {
      // Ported from Params.swift: Health & Aesthetic aggregates data from 3 APIs
      final List<Future<String?>> futures = [
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
        apiService.soapRequest(
          operation: "physicalChemical",
          body:
              '<physicalChemical xmlns="http://tempuri.org/"><UserName>$username</UserName><SiteName>${site.siteName}</SiteName></physicalChemical>',
        ),
      ];

      final results = await Future.wait(futures);

      Map<String, dynamic> aggregatedData = {};

      // Process each response
      for (int i = 0; i < results.length; i++) {
        final res = results[i];
        if (res != null) {
          String op = i == 0
              ? "HealthAesthetic"
              : (i == 1 ? "Metals" : "physicalChemical");
          final jsonStr = apiService.parseSoapResponse(res, op);
          if (jsonStr != "[]") {
            final List<dynamic> dataList = json.decode(jsonStr);
            if (dataList.isNotEmpty) {
              aggregatedData.addAll(dataList[0]);
            }
          }
        }
      }

      // 1. Calculate Color parameter: (0.965 * TSS) + (0.44 * Turbidity)
      final tss = double.tryParse(aggregatedData['TSS']?.toString() ?? "0") ?? 0.0;
      final turb = double.tryParse(aggregatedData['Turbidity']?.toString() ?? "0") ?? 0.0;
      aggregatedData['Color'] = WaterQualityCalculator.calculateColor(
        tss: tss,
        turbidity: turb,
      );

      // 2. Unit conversions as per Swift models
      // Fluoride from Metals is often in µg/L, convert to mg/L if needed
      // Swift MetalsModel: iron/1000, lead/1000
      if (aggregatedData.containsKey('Iron')) {
        final iron = double.tryParse(aggregatedData['Iron'].toString()) ?? 0.0;
        aggregatedData['Iron'] = iron / 1000.0;
      }
      if (aggregatedData.containsKey('Lead')) {
        final lead = double.tryParse(aggregatedData['Lead'].toString()) ?? 0.0;
        aggregatedData['Lead'] = lead / 1000.0;
      }
      if (aggregatedData.containsKey('Flouride')) {
        final f = double.tryParse(aggregatedData['Flouride'].toString()) ?? 0.0;
        aggregatedData['Flouride'] = f / 1000.0;
      }

      _processData(aggregatedData);
    } catch (e) {
      print("Error in aggregated fetch: $e");
    }
  }

  void _processData(Map<String, dynamic> data) {
    final List<ParameterData> list = [];
    final Map<String, double> assessmentMap = {};

    data.forEach((key, value) {
      // Skip metadata
      if (key == "Site_Name" ||
          key == "Last_Update" ||
          key == "Latitude" ||
          key == "Longitude" ||
          key == "siteID") {
        return;
      }

      // Filter unwanted keys as per Swift parseParamResult
      if (key == "chlorophyll" || key == "CO2" || key == "H2S" || 
          key == "HCO3" || key == "Mg" || key == "Strontium" || 
          key == "Vanadium" || key == "Cadmium" || key == "Cobalt" || 
          key == "Nickel" || key == "Silica" || key == "Zinc") {
          // Swift excluding these from display in certain sections
          if (paramName.toUpperCase() != "HEALTH & AESTHETIC") return;
      }

      final double? val = double.tryParse(value?.toString() ?? "");
      if (val != null) {
        final status = WaterQualityCalculator.bisStandards[key]?.getStatus(val) ?? 
                      WaterQualityStatus.good;
        
        list.add(ParameterData(
          name: _formatDisplayName(key),
          value: "${val.toStringAsFixed(2)} ${_getUnit(key)}",
          status: status,
        ));
        assessmentMap[key] = val;
      }
    });

    list.sort((a, b) => a.name.compareTo(b.name));
    parameters.value = list;
    assessment.value = WaterQualityCalculator.calculateConformance(assessmentMap);
  }

  String _formatDisplayName(String key) {
    switch (key) {
      case "pH": return "pH";
      case "EC": return "EC";
      case "TDS": return "Total Dissolved Solids";
      case "DO": return "Dissolved Oxygen";
      case "Total_Coliforms": return "Total Coliforms(Good & Bad)";
      case "E_Coli": return "E-Coli";
      case "Fecal_Coliforms": return "Fecal Coliforms";
      case "Residual_Chlorine": return "Residual Chlorine";
      case "combinedChlorine": return "Combined Chlorine";
      case "Flouride": return "Fluoride";
      default: return key.replaceAll("_", " ");
    }
  }

  String _getUnit(String key) {
    // Ported from getFormattedDataWithUnit
    if (key == "EC") return "dS/m";
    if (key == "Temperature") return "°C";
    if (key == "Hardness" || key == "Alkalinity" || key == "TSS" || 
        key == "DO" || key == "COD" || key == "BOD5" || key == "CO2" || 
        key == "Residual_Chlorine" || key == "combinedChlorine" ||
        key == "H2S" || key == "Iron" || key == "Lead" || key == "Fluoride" ||
        key == "Flouride" || key == "Ca" || key == "Mg" || key == "Na" || key == "Cl" || key == "No3") {
      return "mg/L";
    }
    if (key == "TDS") return "g/L";
    if (key == "ORPe" || key == "ORP") return "mV";
    if (key == "Turbidity") return "NTU";
    if (key == "E_Coli" || key == "Total_Coliforms") return "MPN/100ml";
    if (key == "Color") return "PCU";
    if (key == "chlorophyll") return "µg/L";
    if (key == "Fecal_Coliforms") return "CFU/100ml";
    if (key == "Arsenic") return "µg/L";
    return "";
  }
}
