enum WaterQualityStatus {
  good, // Green
  warning, // Yellow
  danger, // Red
}

class ParameterStatus {
  final double? goodMax;
  final double? warningMax;
  final double? goodMin;
  final double? warningMin;

  const ParameterStatus({
    this.goodMax,
    this.warningMax,
    this.goodMin,
    this.warningMin,
  });

  WaterQualityStatus getStatus(double value) {
    if (goodMin != null && value < goodMin!) return WaterQualityStatus.danger;
    if (goodMax != null && value <= goodMax!) return WaterQualityStatus.good;
    if (warningMax != null && value <= warningMax!)
      return WaterQualityStatus.warning;
    return WaterQualityStatus.danger;
  }
}

class WaterQualityCalculator {
  static double calculateColor({
    required double tss,
    required double turbidity,
  }) {
    // Color (PCU) = (0.965 × TSS) + (0.44 × Turbidity)
    return (0.965 * tss) + (0.44 * turbidity);
  }

  static const Map<String, ParameterStatus> bisStandards = {
    // Physical & Chemical
    "pH": ParameterStatus(goodMin: 6.5, goodMax: 8.5, warningMax: 9.2),
    "EC": ParameterStatus(goodMax: 2.0, warningMax: 3.0),
    "Temperature": ParameterStatus(goodMax: 25.0, warningMax: 40.0),
    "Hardness": ParameterStatus(goodMax: 200.0, warningMax: 600.0),
    "Alkalinity": ParameterStatus(goodMax: 200.0, warningMax: 600.0),
    "TDS": ParameterStatus(goodMax: 500.0, warningMax: 2000.0),

    // Health & Aesthetic
    "TSS": ParameterStatus(goodMax: 2.0, warningMax: 5.0),
    "Turbidity": ParameterStatus(goodMax: 1.0, warningMax: 5.0),
    "DO": ParameterStatus(goodMin: 4.0, goodMax: 10.0),
    "E_Coli": ParameterStatus(goodMax: 0.0, warningMax: 0.0),
    "Total_Coliforms": ParameterStatus(goodMax: 0.0, warningMax: 0.0),
    "Color": ParameterStatus(goodMax: 5.0, warningMax: 15.0),
    "Fluoride": ParameterStatus(goodMax: 1.0, warningMax: 1.5),
    "Arsenic": ParameterStatus(goodMax: 0.01, warningMax: 0.05),
    "Iron": ParameterStatus(goodMax: 0.3, warningMax: 1.0),
    "Lead": ParameterStatus(goodMax: 0.01, warningMax: 0.01),
    "Residual_Chlorine": ParameterStatus(goodMin: 0.2, goodMax: 1.0),

    // Ionic
    "No3": ParameterStatus(goodMax: 45.0, warningMax: 100.0),
    "Ca": ParameterStatus(goodMax: 75.0, warningMax: 200.0),
    "Mg": ParameterStatus(goodMax: 30.0, warningMax: 100.0),
    "Cl": ParameterStatus(goodMax: 250.0, warningMax: 1000.0),
    "Na": ParameterStatus(goodMax: 200.0, warningMax: 200.0),
  };

  static WaterQualityAssessment calculateConformance(
    Map<String, double> parameters,
  ) {
    int green = 0;
    int yellow = 0;
    int total = parameters.length;

    parameters.forEach((name, value) {
      final status =
          bisStandards[name]?.getStatus(value) ?? WaterQualityStatus.good;
      if (status == WaterQualityStatus.good) green++;
      if (status == WaterQualityStatus.warning) yellow++;
    });

    double percentage = total > 0 ? ((green + yellow) / total) * 100 : 0;

    String status = "Not Potable";
    WaterQualityStatus color = WaterQualityStatus.danger;

    if (percentage >= 80) {
      status = "Potable";
      color = WaterQualityStatus.good;
    } else if (percentage >= 60) {
      status = "Potable";
      color = WaterQualityStatus.warning;
    }

    return WaterQualityAssessment(
      conformancePercentage: percentage,
      potabilityStatus: status,
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
