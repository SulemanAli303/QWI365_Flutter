class WaterModel {
  final double fieldCapacity;
  final double refillPoint;
  final double wiltingPoint;
  final double moistureContent;

  WaterModel({
    required this.fieldCapacity,
    required this.refillPoint,
    required this.wiltingPoint,
    required this.moistureContent,
  });

  factory WaterModel.fromJson(Map<String, dynamic> json) {
    return WaterModel(
      fieldCapacity: double.tryParse(json['Field_Capacity'].toString()) ?? 0.0,
      refillPoint: double.tryParse(json['REfill_Point'].toString()) ?? 0.0,
      wiltingPoint: double.tryParse(json['Wilting_Point'].toString()) ?? 0.0,
      moistureContent:
          double.tryParse(json['Moisture_Content'].toString()) ?? 0.0,
    );
  }

  factory WaterModel.empty() {
    return WaterModel(
      fieldCapacity: 0.0,
      refillPoint: 0.0,
      wiltingPoint: 0.0,
      moistureContent: 0.0,
    );
  }
}
