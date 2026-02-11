enum WaterQualityStatus {
  good, // Green
  warning, // Yellow
  danger, // Red
}

enum ParameterGroup {
  microbio,
  toxicMetals,
  disinfection,
  chemistry,
  aesthetic,
}

class ParameterStatus {
  final double? goodMax;
  final double? warningMax;
  final double? goodMin;
  final double? warningMin;
  final ParameterGroup group;

  const ParameterStatus({
    this.goodMax,
    this.warningMax,
    this.goodMin,
    this.warningMin,
    required this.group,
  });

  WaterQualityStatus getStatus(double value) {
    if (goodMin != null && value < goodMin!) return WaterQualityStatus.danger;
    if (goodMax != null && value <= goodMax!) return WaterQualityStatus.good;
    if (warningMax != null && value <= warningMax!)
      return WaterQualityStatus.warning;
    return WaterQualityStatus.danger;
  }
}

class RiskResult {
  final String overallRisk; // "GREEN", "YELLOW", "RED"
  final int riskIndex;
  final String contaminationDegree;
  final List<Map<String, dynamic>> drivers;
  final List<String> redFlags;
  final List<String> missingCriticalTests;
  final double portabilityPercentage;
  final double contaminationPercentage;

  RiskResult({
    required this.overallRisk,
    required this.riskIndex,
    required this.contaminationDegree,
    required this.drivers,
    required this.redFlags,
    required this.missingCriticalTests,
    required this.portabilityPercentage,
    required this.contaminationPercentage,
  });
}

class WaterQualityCalculator {
  static const Map<ParameterGroup, int> groupWeights = {
    ParameterGroup.microbio: 8,
    ParameterGroup.toxicMetals: 6,
    ParameterGroup.disinfection: 4,
    ParameterGroup.chemistry: 2,
    ParameterGroup.aesthetic: 1,
  };

  static double calculateColor({
    required double tss,
    required double turbidity,
  }) {
    return (0.965 * tss) + (0.44 * turbidity);
  }

  static const Map<String, ParameterStatus> bisStandards = {
    // Physical & Chemical
    "pH": ParameterStatus(
      goodMin: 6.5,
      goodMax: 8.5,
      warningMax: 9.2,
      group: ParameterGroup.chemistry,
    ),
    "EC": ParameterStatus(
      goodMax: 2.0,
      warningMax: 3.0,
      group: ParameterGroup.chemistry,
    ),
    "Temperature": ParameterStatus(
      goodMax: 25.0,
      warningMax: 40.0,
      group: ParameterGroup.chemistry,
    ),
    "Hardness": ParameterStatus(
      goodMax: 200.0,
      warningMax: 600.0,
      group: ParameterGroup.chemistry,
    ),
    "Alkalinity": ParameterStatus(
      goodMax: 200.0,
      warningMax: 600.0,
      group: ParameterGroup.chemistry,
    ),
    "TDS": ParameterStatus(
      goodMax: 500.0,
      warningMax: 2000.0,
      group: ParameterGroup.aesthetic,
    ),

    // Health & Aesthetic
    "TSS": ParameterStatus(
      goodMax: 2.0,
      warningMax: 5.0,
      group: ParameterGroup.aesthetic,
    ),
    "Turbidity": ParameterStatus(
      goodMax: 1.0,
      warningMax: 5.0,
      group: ParameterGroup.aesthetic,
    ),
    "DO": ParameterStatus(
      goodMin: 4.0,
      goodMax: 10.0,
      group: ParameterGroup.aesthetic,
    ),
    "E_Coli": ParameterStatus(
      goodMax: 0.0,
      warningMax: 0.0,
      group: ParameterGroup.microbio,
    ),
    "Total_Coliforms": ParameterStatus(
      goodMax: 0.0,
      warningMax: 0.0,
      group: ParameterGroup.microbio,
    ),
    "Fecal_Coliforms": ParameterStatus(
      goodMax: 0.0,
      warningMax: 0.0,
      group: ParameterGroup.microbio,
    ),
    "Color": ParameterStatus(
      goodMax: 5.0,
      warningMax: 15.0,
      group: ParameterGroup.aesthetic,
    ),
    "Fluoride": ParameterStatus(
      goodMax: 1.0,
      warningMax: 1.5,
      group: ParameterGroup.toxicMetals,
    ),
    "Flouride": ParameterStatus(
      goodMax: 1.0,
      warningMax: 1.5,
      group: ParameterGroup.toxicMetals,
    ),
    "Arsenic": ParameterStatus(
      goodMax: 0.01,
      warningMax: 0.05,
      group: ParameterGroup.toxicMetals,
    ),
    "Iron": ParameterStatus(
      goodMax: 0.3,
      warningMax: 1.0,
      group: ParameterGroup.toxicMetals,
    ),
    "Lead": ParameterStatus(
      goodMax: 0.01,
      warningMax: 0.01,
      group: ParameterGroup.toxicMetals,
    ),
    "Manganese": ParameterStatus(
      goodMax: 0.1,
      warningMax: 0.3,
      group: ParameterGroup.toxicMetals,
    ),
    "Residual_Chlorine": ParameterStatus(
      goodMin: 0.2,
      goodMax: 1.0,
      group: ParameterGroup.disinfection,
    ),
    "combinedChlorine": ParameterStatus(
      goodMin: 0.0,
      goodMax: 1.0,
      group: ParameterGroup.disinfection,
    ),

    // Ionic
    "No3": ParameterStatus(
      goodMax: 45.0,
      warningMax: 45.0,
      group: ParameterGroup.chemistry,
    ),
    "Ca": ParameterStatus(
      goodMax: 75.0,
      warningMax: 200.0,
      group: ParameterGroup.chemistry,
    ),
    "Mg": ParameterStatus(
      goodMax: 30.0,
      warningMax: 100.0,
      group: ParameterGroup.chemistry,
    ),
    "Cl": ParameterStatus(
      goodMax: 250.0,
      warningMax: 1000.0,
      group: ParameterGroup.chemistry,
    ),
    "Na": ParameterStatus(
      goodMax: 200.0,
      warningMax: 200.0,
      group: ParameterGroup.chemistry,
    ),
  };

  static RiskResult calculateRisk(Map<String, double> parameters) {
    double totalScore = 0;
    double maxScore = 0;
    int redCount = 0;
    List<Map<String, dynamic>> allParamScores = [];

    // Critical tests to check for missing
    final criticalTests = ["E_Coli", "Residual_Chlorine", "pH", "Turbidity"];
    List<String> missingCritical = [];
    for (var test in criticalTests) {
      if (!parameters.containsKey(test)) {
        missingCritical.add(test.replaceAll("_", ""));
      }
    }

    parameters.forEach((name, value) {
      final standard = bisStandards[name];
      if (standard != null) {
        final status = standard.getStatus(value);
        int basePoints = 0;
        String colorStr = "GREEN";
        if (status == WaterQualityStatus.warning) {
          basePoints = 1;
          colorStr = "YELLOW";
        } else if (status == WaterQualityStatus.danger) {
          basePoints = 3;
          colorStr = "RED";
          redCount++;
        }

        final weight = groupWeights[standard.group] ?? 1;
        final paramScore = basePoints * weight;
        totalScore += paramScore;
        maxScore += 3 * weight;

        allParamScores.add({
          "name": name.replaceAll("_", " "),
          "color": colorStr,
          "impact": standard.group.toString().split('.').last.toUpperCase(),
          "param_score": paramScore,
        });
      }
    });

    int riskIndex = maxScore > 0 ? (100 * totalScore / maxScore).round() : 0;

    // Overall Risk Level based on Risk Index
    String overallRisk = "GREEN";
    if (riskIndex >= 60) {
      overallRisk = "RED";
    } else if (riskIndex >= 25) {
      overallRisk = "YELLOW";
    }

    // Tie-breaker 1 — “Red count” escalation
    if (overallRisk == "GREEN" && redCount >= 2) {
      overallRisk = "YELLOW";
    }
    if (overallRisk == "YELLOW" && redCount >= 3) {
      overallRisk = "RED";
    }

    // Tie-breaker 2 — Disinfection borderline + turbidity high
    final chlorineStatus = parameters.containsKey("Residual_Chlorine")
        ? bisStandards["Residual_Chlorine"]?.getStatus(
            parameters["Residual_Chlorine"]!,
          )
        : null;
    final turbidityStatus = parameters.containsKey("Turbidity")
        ? bisStandards["Turbidity"]?.getStatus(parameters["Turbidity"]!)
        : null;

    if (chlorineStatus == WaterQualityStatus.warning &&
        (turbidityStatus == WaterQualityStatus.warning ||
            turbidityStatus == WaterQualityStatus.danger)) {
      if (overallRisk == "GREEN")
        overallRisk = "YELLOW";
      else if (overallRisk == "YELLOW")
        overallRisk = "RED";
    }

    // Contamination Degree
    String contaminationDegree = "Very Low";
    if (riskIndex > 80)
      contaminationDegree = "Severe";
    else if (riskIndex > 60)
      contaminationDegree = "Very High";
    else if (riskIndex > 45)
      contaminationDegree = "High";
    else if (riskIndex > 25)
      contaminationDegree = "Moderate";
    else if (riskIndex > 10)
      contaminationDegree = "Low";

    // Sort drivers by param_score
    allParamScores.sort((a, b) => b['param_score'].compareTo(a['param_score']));
    final drivers = allParamScores.take(5).toList();

    double portabilityPercentage = 100.0 - riskIndex.toDouble();
    double contaminationPercentage = riskIndex.toDouble();

    return RiskResult(
      overallRisk: overallRisk,
      riskIndex: riskIndex,
      contaminationDegree: contaminationDegree,
      drivers: drivers,
      redFlags: redCount > 0 ? ["$redCount Red parameters detected"] : [],
      missingCriticalTests: missingCritical,
      portabilityPercentage: portabilityPercentage,
      contaminationPercentage: contaminationPercentage,
    );
  }

  // Keep compatibility for conformancy UI if needed, but we will use calculateRisk mostly now
  static WaterQualityAssessment calculateConformance(
    Map<String, double> parameters,
  ) {
    final risk = calculateRisk(parameters);

    WaterQualityStatus color;
    if (risk.overallRisk == "RED") {
      color = WaterQualityStatus.danger;
    } else if (risk.overallRisk == "YELLOW") {
      color = WaterQualityStatus.warning;
    } else {
      color = WaterQualityStatus.good;
    }

    return WaterQualityAssessment(
      conformancePercentage: risk.portabilityPercentage,
      potabilityStatus: risk.overallRisk == "RED" ? "Not Potable" : "Potable",
      statusColor: color,
    );
  }
}

class WaterQualityAssessment {
  final double conformancePercentage;
  final String potabilityStatus;
  final WaterQualityStatus statusColor;

  WaterQualityAssessment({
    required this.conformancePercentage,
    required this.potabilityStatus,
    required this.statusColor,
  });
}
