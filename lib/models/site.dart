import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class Site {
  final String siteName;
  final double latitude;
  final double longitude;
  final String lastUpdate;

  Site({
    required this.siteName,
    required this.latitude,
    required this.longitude,
    required this.lastUpdate,
  });

  LatLng get coordinate => LatLng(latitude, longitude);

  String get formattedLastUpdate {
    if (lastUpdate.isEmpty) {
      return "N/A";
    }

    try {
      // Assuming Swift's "dd/MM/yyyy kk:mm:ss" format
      // Note: kk is 1-24, HH is 0-23. Data might use 1-24.
      final DateFormat inputFormat = DateFormat("dd/MM/yyyy HH:mm:ss");
      final DateTime dateTime = inputFormat.parse(
        lastUpdate.replaceAll("24:", "00:"),
      );
      final DateFormat outputFormat = DateFormat("dd MMM yyyy, hh:mm a");
      return outputFormat.format(dateTime);
    } catch (e) {
      return lastUpdate;
    }
  }

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      siteName: json['Site_Name'] ?? "",
      latitude: double.tryParse(json['Latitude']?.toString() ?? "0") ?? 0.0,
      longitude: double.tryParse(json['Longitude']?.toString() ?? "0") ?? 0.0,
      lastUpdate: json['Last_Update'] ?? "",
    );
  }
}
