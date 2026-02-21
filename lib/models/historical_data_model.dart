class HistoricalDataModel {
  final double value;
  final String dateTime;
  final String deviceName;
  final double? refillPoint;

  HistoricalDataModel({
    required this.value,
    required this.dateTime,
    required this.deviceName,
    this.refillPoint,
  });

  factory HistoricalDataModel.fromMap(String dataString) {
    // Android code splits by '|'
    // mcArr.add(bus1 + "|" + time + "|" + dName + "|" + refill);
    final parts = dataString.split('|');
    return HistoricalDataModel(
      value: double.tryParse(parts[0]) ?? 0.0,
      dateTime: parts[1],
      deviceName: parts[2],
      refillPoint: parts.length > 3 ? double.tryParse(parts[3]) : null,
    );
  }
}
