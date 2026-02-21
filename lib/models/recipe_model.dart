class RecipeModel {
  final String siteName;
  final double refillPoint;
  final double moistureContent;
  final String insertionDate;
  final double evapotranspiration;
  final double temperature;
  final double rainFall;
  final double irrigationAmount;
  final String irrigationTime;
  final String status;

  RecipeModel({
    required this.siteName,
    required this.refillPoint,
    required this.moistureContent,
    required this.insertionDate,
    required this.evapotranspiration,
    required this.temperature,
    required this.rainFall,
    required this.irrigationAmount,
    required this.irrigationTime,
    required this.status,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      siteName: json['Site_Name']?.toString() ?? '',
      refillPoint:
          double.tryParse(
            json['REfill_Point']?.toString() ??
                json['Refill_Point']?.toString() ??
                '0',
          ) ??
          0.0,
      moistureContent:
          double.tryParse(
            json['Bus_1_Reading']?.toString() ??
                json['Moisture_Content']?.toString() ??
                '0',
          ) ??
          0.0,
      insertionDate:
          (json['Insertion_Date'] ?? json['insertion_date'])?.toString() ?? '',
      evapotranspiration:
          double.tryParse(json['Evapotranspiration']?.toString() ?? '0') ?? 0.0,
      temperature:
          double.tryParse(
            json['Temprature']?.toString() ??
                json['Temperature']?.toString() ??
                '0',
          ) ??
          0.0,
      rainFall: double.tryParse(json['RainFall']?.toString() ?? '0') ?? 0.0,
      irrigationAmount:
          double.tryParse(json['Irrigation_Amount']?.toString() ?? '0') ?? 0.0,
      irrigationTime: json['Irrigation_Time']?.toString() ?? '',
      status: json['Status']?.toString() ?? '',
    );
  }
}
