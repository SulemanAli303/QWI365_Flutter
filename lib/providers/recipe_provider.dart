import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/network_api_service.dart';
import '../utils/api_urls.dart';
import 'package:intl/intl.dart';

/// A single date-grouped, averaged entry for the History tab.
class ProcessedHistoryEntry {
  final String date; // formatted display date e.g. "20 February 2025"
  final String rawDate; // dd/MM/yyyy used as sort key
  final double avgIrrigationAmount;
  final double avgRefillPoint;
  final double avgMoisture;
  final double avgEvapotranspiration;
  final double avgTemperature;
  final double avgRainFall;

  ProcessedHistoryEntry({
    required this.date,
    required this.rawDate,
    required this.avgIrrigationAmount,
    required this.avgRefillPoint,
    required this.avgMoisture,
    required this.avgEvapotranspiration,
    required this.avgTemperature,
    required this.avgRainFall,
  });
}

class RecipeProvider with ChangeNotifier {
  final NetworkApiService _apiService = NetworkApiService();

  List<RecipeModel> _activeRecipes = [];
  List<RecipeModel> get activeRecipes => _activeRecipes;

  List<RecipeModel> _recipeHistory = [];
  List<RecipeModel> get recipeHistory => _recipeHistory;

  List<ProcessedHistoryEntry> _processedHistory = [];
  List<ProcessedHistoryEntry> get processedHistory => _processedHistory;

  // ── Separate loading flags so tabs don't interfere ──
  bool _loadingActive = false;
  bool get loadingActive => _loadingActive;

  bool _loadingHistory = false;
  bool get loadingHistory => _loadingHistory;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Keep for any legacy consumers
  bool get loading => _loadingActive || _loadingHistory;

  void _setLoadingActive(bool value) {
    _loadingActive = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  void _setLoadingHistory(bool value) {
    _loadingHistory = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchActiveRecipes(String username) async {
    _setLoadingActive(true);
    try {
      final response = await _apiService.getPostApiResponse(
        ApiUrls.recipesUrl,
        soapAction: ApiUrls.recipesAction,
        params: {'_methodName': ApiUrls.recipesMethod, 'UserName': username},
      );

      final List<dynamic> result = NetworkApiService.parseSoapResponse(
        response,
        'RecipesResult',
      );
      final List<RecipeModel> allRecipes = result
          .map((e) => RecipeModel.fromJson(e))
          .toList();

      // Sort: Critical → Caution → Recent → Others
      // This ensures we show EVERYTHING but keep Android's priority at top.
      // This helps debug if sites are missing because of status.
      final List<RecipeModel> sorted = [];
      for (final r in allRecipes) {
        if (r.status.trim() == 'Critical') sorted.add(r);
      }
      for (final r in allRecipes) {
        if (r.status.trim() == 'Caution') sorted.add(r);
      }
      for (final r in allRecipes) {
        if (r.status.trim() == 'Recent') sorted.add(r);
      }
      // Add anything else that wasn't already added
      for (final r in allRecipes) {
        if (!['Critical', 'Caution', 'Recent'].contains(r.status.trim())) {
          sorted.add(r);
        }
      }

      _activeRecipes = sorted;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoadingActive(false);
    }
  }

  Future<void> fetchRecipeHistory(
    String siteName,
    String toDate, // dd/MM/yyyy  (today)
    String fromDate, // dd/MM/yyyy  (6 days ago)
  ) async {
    _setLoadingHistory(true);
    try {
      final response = await _apiService.getPostApiResponse(
        ApiUrls.recipeHistoryUrl,
        soapAction: ApiUrls.recipeHistoryAction,
        params: {
          '_methodName': ApiUrls.recipeHistoryMethod,
          'SiteName': siteName,
          'FromDate': fromDate,
          'ToDate': toDate,
        },
      );

      final List<dynamic> result = NetworkApiService.parseSoapResponse(
        response,
        'HistoricalRecipeResult',
      );
      _recipeHistory = result.map((e) => RecipeModel.fromJson(e)).toList();

      // Build date-grouped averages – mirrors Recipes.java processRecipesHistoryArray
      _processedHistory = _buildProcessedHistory(
        _recipeHistory,
        fromDate,
        toDate,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoadingHistory(false);
    }
  }

  // ── Date-grouping / averaging logic ─────────────────────────────────────

  /// Returns a list of [ProcessedHistoryEntry] for the past 7 days,
  /// only including days that have at least one non-zero record.
  List<ProcessedHistoryEntry> _buildProcessedHistory(
    List<RecipeModel> records,
    String fromDateStr, // dd/MM/yyyy
    String toDateStr, // dd/MM/yyyy
  ) {
    final sdfIn = DateFormat('dd/MM/yyyy');
    final sdfDisplay = DateFormat('dd MMMM yyyy');

    // Build list of date strings covering [fromDate .. toDate]
    final List<String> dateKeys = _getDatesArray(fromDateStr, toDateStr, sdfIn);

    final List<ProcessedHistoryEntry> entries = [];

    for (final dateKey in dateKeys) {
      // Collect all records that fall on this date
      final List<RecipeModel> dayRecords = records.where((r) {
        return _normaliseDate(r.insertionDate).contains(dateKey);
      }).toList();

      if (dayRecords.isEmpty) continue;

      final double avgAmount = _avg(
        dayRecords.map((r) => r.irrigationAmount).toList(),
      );
      final double avgRefill = _avg(
        dayRecords.map((r) => r.refillPoint).toList(),
      );
      final double avgMc = _avg(
        dayRecords.map((r) => r.moistureContent).toList(),
      );
      final double avgEvapo = _avg(
        dayRecords.map((r) => r.evapotranspiration).toList(),
      );
      final double avgTemp = _avg(
        dayRecords.map((r) => r.temperature).toList(),
      );
      final double avgRain = _avg(dayRecords.map((r) => r.rainFall).toList());

      // Skip if all averages are zero (mirrors Android check)
      if (avgAmount == 0.0 &&
          avgRefill == 0.0 &&
          avgMc == 0.0 &&
          avgEvapo == 0.0 &&
          avgTemp == 0.0 &&
          avgRain == 0.0) {
        continue;
      }

      String displayDate = dateKey;
      try {
        final parsed = sdfIn.parseStrict(dateKey);
        displayDate = sdfDisplay.format(parsed);
      } catch (_) {}

      entries.add(
        ProcessedHistoryEntry(
          date: displayDate,
          rawDate: dateKey,
          avgIrrigationAmount: avgAmount,
          avgRefillPoint: avgRefill,
          avgMoisture: avgMc,
          avgEvapotranspiration: avgEvapo,
          avgTemperature: avgTemp,
          avgRainFall: avgRain,
        ),
      );
    }

    // Reverse-chronological order (newest first)
    entries.sort((a, b) {
      try {
        final da = sdfIn.parseStrict(a.rawDate);
        final db = sdfIn.parseStrict(b.rawDate);
        return db.compareTo(da);
      } catch (_) {
        return 0;
      }
    });

    return entries;
  }

  /// Generates list of dd/MM/yyyy date strings from [fromDate] to [toDate] inclusive.
  List<String> _getDatesArray(
    String fromDateStr,
    String toDateStr,
    DateFormat sdf,
  ) {
    final List<String> dates = [];
    try {
      DateTime current = sdf.parseStrict(fromDateStr);
      final DateTime end = sdf.parseStrict(toDateStr);
      while (!current.isAfter(end)) {
        dates.add(sdf.format(current));
        current = current.add(const Duration(days: 1));
      }
    } catch (_) {}
    return dates;
  }

  /// Strips the time portion from an insertionDate so we can match against
  /// a plain dd/MM/yyyy date key.
  String _normaliseDate(String insertionDate) {
    // API returns dates like "2025-02-14T00:00:00" or "14/02/2025 00:00:00"
    // We convert to dd/MM/yyyy for comparison.
    try {
      // Try ISO format first
      final dt = DateTime.parse(insertionDate.replaceAll('T', ' '));
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return insertionDate; // already in expected format or fallback
    }
  }

  double _avg(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.fold(0.0, (sum, v) => sum + v) / values.length;
  }
}
