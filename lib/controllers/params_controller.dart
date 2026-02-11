import 'package:get/get.dart';
import 'package:water365/controllers/sites_controller.dart';
import 'package:water365/models/site.dart';
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
      loadParameters();
    }
  }

  void loadParameters() {
    isLoading.value = true;
    try {
      final sitesController = Get.find<SitesController>();
      final rawData = sitesController.siteRawData[site.siteName];
      if (rawData == null) {
        parameters.clear();
        return;
      }

      final category = paramName.toUpperCase();
      Map<String, dynamic> displayData = {};

      if (category == "HEALTH & AESTHETIC") {
        // Aggregate from 3 APIs as per original logic
        final ha = rawData['HealthAesthetic'] ?? {};
        final metals = rawData['Metals'] ?? {};
        final pc = rawData['physicalChemical'] ?? {};

        displayData.addAll(ha);
        displayData.addAll(metals);
        displayData.addAll(pc);

        // Apply specific Color calculation and unit conversions for this section ONLY
        final tss =
            double.tryParse(displayData['TSS']?.toString() ?? "0") ?? 0.0;
        final turb =
            double.tryParse(displayData['Turbidity']?.toString() ?? "0") ?? 0.0;
        displayData['Color'] = WaterQualityCalculator.calculateColor(
          tss: tss,
          turbidity: turb,
        );

        if (displayData.containsKey('Iron')) {
          displayData['Iron'] =
              (double.tryParse(displayData['Iron'].toString()) ?? 0.0) / 1000.0;
        }
        if (displayData.containsKey('Lead')) {
          displayData['Lead'] =
              (double.tryParse(displayData['Lead'].toString()) ?? 0.0) / 1000.0;
        }
        if (displayData.containsKey('Flouride')) {
          displayData['Flouride'] =
              (double.tryParse(displayData['Flouride'].toString()) ?? 0.0) /
              1000.0;
        }
      } else {
        String op = "";
        if (category == "PHYSICAL & CHEMICAL")
          op = "physicalChemical";
        else if (category == "METALS")
          op = "Metals";
        else if (category == "IONIC FEATURES")
          op = "IonicFeatures";

        displayData = Map<String, dynamic>.from(rawData[op] ?? {});
      }

      _processData(displayData);
    } catch (e) {
      print("Error loading parameters: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _processData(Map<String, dynamic> data) {
    final List<ParameterData> list = [];
    final Map<String, double> assessmentMap = {};
    final category = paramName.toUpperCase();

    data.forEach((key, value) {
      // Skip metadata
      if (key == "Site_Name" ||
          key == "Last_Update" ||
          key == "Latitude" ||
          key == "Longitude" ||
          key == "siteID") {
        return;
      }

      // Filter unwanted keys as per original blacklist (except for Health & Aesthetic)
      if (category != "HEALTH & AESTHETIC") {
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
      }

      final double? val = double.tryParse(value?.toString() ?? "");
      if (val != null) {
        // We use the converted value for status but we should ensure key mapping is correct
        final status =
            WaterQualityCalculator.bisStandards[key]?.getStatus(val) ??
            WaterQualityStatus.good;

        list.add(
          ParameterData(
            name: _formatDisplayName(key),
            value: "${val.toStringAsFixed(2)} ${_getUnit(key)}",
            status: status,
          ),
        );
        assessmentMap[key] = val;
      }
    });

    list.sort((a, b) => a.name.compareTo(b.name));
    parameters.value = list;

    // Calculate assessment for header based on current visible parameters
    assessment.value = WaterQualityCalculator.calculateConformance(
      assessmentMap,
    );
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
    if (key == "Arsenic") return "µg/L";
    return "";
  }
}
