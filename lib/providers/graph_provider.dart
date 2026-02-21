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

      for (var e in result) {
        final data = HistoricalDataModel.fromMap(e.toString());
        final dType = deviceTypeMap[data.deviceName];
        if (dType == null) continue;

        switch (dType) {
          case "10HS":
          case "GS1":
            _graphData['Moisture']!.add(data);
            break;
          case "5TM":
            // In Android, 5TM adds value to mcArr (bus1) and tempArr (bus2)
            // But the string format seems to suggest only one value per string.
            // Let's check Android Graphs.java line 690-734 again.
            _graphData['Moisture']!.add(data);
            // In Android: tempArr.add(bus2 + "|" + time + "|" + dName);
            // This implies the SAME result row might be processed multiple times?
            // No, looking at Graphs.java, bus1, bus2, bus3 are parsed from ONE JSONObject.
            // But the result from server is "result.toString()" which is a JSONArray.
            // Each entry in JSONArray is parsed.
            // Wait, if the entry is "value|time|deviceName", where are bus2, bus3?
            // Let's re-read Graphs.java parseGraphData:
            // "String bus1 = jObject.getString("bus_1_Reading");"
            // Ah, it's a JSON string!
            break;
          case "GS3":
          case "5TE":
          case "EnviroScan":
            _graphData['Moisture']!.add(data);
            break;
          case "PYR":
            _graphData['Solar']!.add(data);
            break;
          case "VP4":
            _graphData['Temperature']!.add(data);
            break;
          case "ECRN50":
          case "ECRN100":
            _graphData['Rainfall']!.add(data);
            break;
          case "PH":
            _graphData['PH']!.add(data);
            break;
          case "EC":
            _graphData['EC']!.add(data);
            break;
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
