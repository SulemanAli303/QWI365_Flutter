import 'package:flutter/material.dart';
import '../models/historical_data_model.dart';
import '../services/network_api_service.dart';
import '../utils/api_urls.dart';

class GraphProvider with ChangeNotifier {
  final NetworkApiService _apiService = NetworkApiService();

  Map<String, List<HistoricalDataModel>> _graphData = {};
  Map<String, List<HistoricalDataModel>> get graphData => _graphData;

  bool _loading = false;
  bool get loading => _loading;

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> fetchHistoricalGraph(
    String siteName,
    String fromDate,
    String toDate,
    String username,
    Map<String, String> deviceTypeMap,
  ) async {
    setLoading(true);
    try {
      final response = await _apiService.getPostApiResponse(
        ApiUrls.graphsUrl,
        soapAction: ApiUrls.graphsAction,
        params: {
          '_methodName': ApiUrls.graphsMethod,
          'UserName': username,
          'SiteName': siteName,
          'FromDate': fromDate,
          'ToDate': toDate,
        },
      );

      final List<dynamic> result = NetworkApiService.parseSoapResponse(
        response,
        'HistoricalGraphResult',
      );

      _graphData = {
        'Moisture': [],
        'Temperature': [],
        'EC': [],
        'Solar': [],
        'Humidity': [],
        'Pressure': [],
        'PH': [],
        'Rainfall': [],
      };

      // Parse graph data similar to Java version parseGraphData
      for (String key in deviceTypeMap.keys) {
        for (var e in result) {
          final data = HistoricalDataModel.fromMap(e);
          final dType = deviceTypeMap[data.deviceName];

          if (key == data.deviceName && dType != null) {
            switch (dType) {
              case "10HS":
              case "GS1":
                _graphData['Moisture']!.add(
                  HistoricalDataModel(
                    bus1Reading: data.bus1Reading,
                    dateTime: data.dateTime,
                    deviceName: data.deviceName,
                    refillPoint: data.refillPoint,
                  ),
                );
                break;
              case "5TM":
                // Add moisture (bus1)
                _graphData['Moisture']!.add(
                  HistoricalDataModel(
                    bus1Reading: data.bus1Reading,
                    dateTime: data.dateTime,
                    deviceName: data.deviceName,
                    refillPoint: data.refillPoint,
                  ),
                );
                // Add temperature (bus2)
                if (data.bus2Reading != null) {
                  _graphData['Temperature']!.add(
                    HistoricalDataModel(
                      bus1Reading: data.bus2Reading!,
                      dateTime: data.dateTime,
                      deviceName: data.deviceName,
                    ),
                  );
                }
                break;
              case "GS3":
              case "5TE":
              case "EnviroScan":
                // Add moisture (bus1)
                _graphData['Moisture']!.add(
                  HistoricalDataModel(
                    bus1Reading: data.bus1Reading,
                    dateTime: data.dateTime,
                    deviceName: data.deviceName,
                    refillPoint: data.refillPoint,
                  ),
                );
                // Add temperature (bus2)
                if (data.bus2Reading != null) {
                  _graphData['Temperature']!.add(
                    HistoricalDataModel(
                      bus1Reading: data.bus2Reading!,
                      dateTime: data.dateTime,
                      deviceName: data.deviceName,
                    ),
                  );
                }
                // Add EC (bus3)
                if (data.bus3Reading != null) {
                  _graphData['EC']!.add(
                    HistoricalDataModel(
                      bus1Reading: data.bus3Reading!,
                      dateTime: data.dateTime,
                      deviceName: data.deviceName,
                    ),
                  );
                }
                break;
              case "PYR":
                _graphData['Solar']!.add(
                  HistoricalDataModel(
                    bus1Reading: data.bus1Reading,
                    dateTime: data.dateTime,
                    deviceName: data.deviceName,
                  ),
                );
                break;
              case "VP4":
                // Add temperature (bus1)
                _graphData['Temperature']!.add(
                  HistoricalDataModel(
                    bus1Reading: data.bus1Reading,
                    dateTime: data.dateTime,
                    deviceName: data.deviceName,
                  ),
                );
                // Add humidity (bus2)
                if (data.bus2Reading != null) {
                  _graphData['Humidity']!.add(
                    HistoricalDataModel(
                      bus1Reading: data.bus2Reading!,
                      dateTime: data.dateTime,
                      deviceName: data.deviceName,
                    ),
                  );
                }
                // Add pressure (bus3)
                if (data.bus3Reading != null) {
                  _graphData['Pressure']!.add(
                    HistoricalDataModel(
                      bus1Reading: data.bus3Reading!,
                      dateTime: data.dateTime,
                      deviceName: data.deviceName,
                    ),
                  );
                }
                break;
              case "ECRN50":
              case "ECRN100":
                _graphData['Rainfall']!.add(
                  HistoricalDataModel(
                    bus1Reading: data.bus1Reading,
                    dateTime: data.dateTime,
                    deviceName: data.deviceName,
                  ),
                );
                break;
              case "PH":
                _graphData['PH']!.add(
                  HistoricalDataModel(
                    bus1Reading: data.bus1Reading,
                    dateTime: data.dateTime,
                    deviceName: data.deviceName,
                  ),
                );
                break;
              case "EC":
                _graphData['EC']!.add(
                  HistoricalDataModel(
                    bus1Reading: data.bus1Reading,
                    dateTime: data.dateTime,
                    deviceName: data.deviceName,
                  ),
                );
                break;
            }
          }
        }
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      setLoading(false);
    }
  }
}
