class SiteModel {
  final String siteName;
  final double latitude;
  final double longitude;
  final String? deviceType;
  final String? deviceName;
  final String? lastUpdate;
  final double? bus1Reading;
  final double? bus2Reading;
  final double? bus3Reading;
  final double? bus4Reading;
  final double? refillPoint;

  SiteModel({
    required this.siteName,
    required this.latitude,
    required this.longitude,
    this.deviceType,
    this.deviceName,
    this.lastUpdate,
    this.bus1Reading,
    this.bus2Reading,
    this.bus3Reading,
    this.bus4Reading,
    this.refillPoint,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      siteName: json['Site_Name'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      deviceType: json['Device_Type'],
      deviceName: json['Device_Name'],
      lastUpdate: json['last_Update'],
      bus1Reading: double.tryParse(json['bus_1_reading'].toString()),
      bus2Reading: double.tryParse(json['bus_2_reading'].toString()),
      bus3Reading: double.tryParse(json['bus_3_reading'].toString()),
      bus4Reading: double.tryParse(json['bus_4_reading'].toString()),
      refillPoint: double.tryParse(json['REfill_Point'].toString()),
    );
  }
}
