class DeviceModel {
  final String deviceName;
  final double bus1Reading;
  final double bus2Reading;
  final double bus3Reading;
  final double bus4Reading;
  final double refillPoint;
  final String insertionDate;
  final String deviceId;
  final String deviceType;

  DeviceModel({
    required this.deviceName,
    required this.deviceId,
    required this.bus1Reading,
    required this.bus2Reading,
    required this.bus3Reading,
    required this.bus4Reading,
    required this.refillPoint,
    required this.insertionDate,
    required this.deviceType,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceName: json['Device_Name'] ?? '',
      bus1Reading: double.tryParse(json['bus_1_Reading'].toString()) ?? 0.0,
      bus2Reading: double.tryParse(json['bus_2_Reading'].toString()) ?? 0.0,
      bus3Reading: double.tryParse(json['bus_3_reading'].toString()) ?? 0.0,
      bus4Reading: double.tryParse(json['bus_4_Reading'].toString()) ?? 0.0,
      refillPoint: double.tryParse(json['REfill_Point'].toString()) ?? 0.0,
      deviceId: json['Device_Id']?.toString() ?? '',
      insertionDate: json['Insertion_Date'] ?? '',
      deviceType: json['Device_Type'] ?? '',
    );
  }
}
