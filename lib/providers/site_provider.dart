import 'package:flutter/material.dart';
import '../models/site_model.dart';
import '../models/device_model.dart';
import '../models/water_model.dart';
import '../services/network_api_service.dart';
import '../utils/api_urls.dart';

class SiteProvider with ChangeNotifier {
  final NetworkApiService _apiService = NetworkApiService();

  List<SiteModel> _sites = [];
  List<SiteModel> get sites => _sites;

  List<DeviceModel> _devices = [];
  List<DeviceModel> get devices => _devices;

  bool _loading = false;
  bool get loading => _loading;

  WaterModel? _waterModel;
  WaterModel? get waterModel => _waterModel;

  String? _selectedSiteName;
  String? get selectedSiteName => _selectedSiteName;

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setSelectedSite(String? siteName) {
    _selectedSiteName = siteName;
    notifyListeners();
  }

  Future<void> fetchSites(String username) async {
    setLoading(true);
    try {
      final response = await _apiService.getPostApiResponse(
        ApiUrls.siteScreenUrl,
        soapAction: ApiUrls.siteScreenAction,
        params: {'_methodName': ApiUrls.siteScreenMethod, 'UserName': username},
      );

      final List<dynamic> result = NetworkApiService.parseSoapResponse(
        response,
        'SiteScreenResult',
      );

      // Deduplicate sites - keep only first occurrence of each site name
      // This handles multiple devices at the same site
      final Map<String, SiteModel> uniqueSitesMap = {};
      for (var item in result) {
        final site = SiteModel.fromJson(item);
        if (!uniqueSitesMap.containsKey(site.siteName)) {
          uniqueSitesMap[site.siteName] = site;
        }
      }

      _sites = uniqueSitesMap.values.toList();
      _selectedSiteName = _sites.first?.siteName ?? "";
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchDeviceDetails(String siteName, String username) async {
    setLoading(true);
    try {
      final response = await _apiService.getPostApiResponse(
        ApiUrls.deviceUrl,
        soapAction: ApiUrls.deviceAction,
        params: {
          '_methodName': ApiUrls.deviceMethod,
          'UserName': username,
          'SiteName': siteName,
        },
      );

      final List<dynamic> result = NetworkApiService.parseSoapResponse(
        response,
        'DeviceDetailsResult',
      );
      _devices = result.map((e) => DeviceModel.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchAvailableWater(String siteName) async {
    setLoading(true);
    try {
      final response = await _apiService.getPostApiResponse(
        ApiUrls.avUrl,
        soapAction: ApiUrls.avAction,
        params: {'_methodName': ApiUrls.avMethod, 'SiteName': siteName},
      );

      final dynamic result = NetworkApiService.parseSoapResponse(
        response,
        'AvailableWaterHorticultureResult',
      );

      if (result is List && result.isNotEmpty) {
        _waterModel = WaterModel.fromJson(result.last);
      } else {
        _waterModel = null;
      }
      notifyListeners();
    } catch (e) {
      _waterModel = null;
      notifyListeners();
      rethrow;
    } finally {
      setLoading(false);
    }
  }
}
