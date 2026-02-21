class HistoricalDataModel {
  final double bus1Reading;
  final double? bus2Reading;
  final double? bus3Reading;
  final String dateTime;
  final String deviceName;
  final double? refillPoint;

  HistoricalDataModel({
    required this.bus1Reading,
    this.bus2Reading,
    this.bus3Reading,
    required this.dateTime,
    required this.deviceName,
    this.refillPoint,
  });

  factory HistoricalDataModel.fromMap(Map<String, dynamic> data) {
    return HistoricalDataModel(
      bus1Reading: (data['bus_1_Reading'] as num?)?.toDouble() ?? 0.0,
      bus2Reading: (data['bus_2_Reading'] as num?)?.toDouble(),
      bus3Reading: (data['bus_3_Reading'] as num?)?.toDouble(),
      dateTime: data['Insertion_Date'] as String? ?? '',
      deviceName: data['Device_Name'] as String? ?? '',
      refillPoint: _parseRefillPoint(data['REfill_point']),
    );
  }

  static double? _parseRefillPoint(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
