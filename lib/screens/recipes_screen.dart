import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qwi365/utils/app_colors.dart';
import '../providers/auth_provider.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../providers/site_provider.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// dd/MM/yyyy – same format the API and Android code use
  final DateFormat _apiDateFmt = DateFormat('dd/MM/yyyy');

  /// For displaying dates on ACTIVE tab cards  e.g.  "14 Feb 25"
  final DateFormat _displayFmt = DateFormat('dd MMM yy');

  /// For displaying time on ACTIVE tab cards  e.g.  "08:45 AM"
  final DateFormat _timeFmt = DateFormat('hh:mm a');

  // History tab site selector state
  String? _selectedHistorySite;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveRecipes();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    // Guard: only act when the tab has fully settled (not mid-animation)
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      _fetchHistoryForSelectedSite();
    }
  }

  void _fetchActiveRecipes() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    if (authProvider.username != null) {
      recipeProvider.fetchActiveRecipes(authProvider.username!).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading recipes: $e')));
        }
      });
    }
  }

  void _fetchHistoryForSelectedSite() {
    if (_selectedHistorySite == null) return;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final today = _apiDateFmt.format(DateTime.now());
    final sixDaysAgo = _apiDateFmt.format(
      DateTime.now().subtract(const Duration(days: 6)),
    );
    recipeProvider
        .fetchRecipeHistory(_selectedHistorySite!, today, sixDaysAgo)
        .catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading history: $e')),
            );
          }
        });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _fmt(double d) {
    if (d % 1 == 0) return d.toStringAsFixed(0);
    return d.toStringAsFixed(1);
  }

  String _parseDisplayDate(String raw) {
    try {
      final cleaned = raw.replaceAll('T', ' ');
      final parts = cleaned.split(' ');
      final dt = DateTime.parse(parts[0]);
      return _displayFmt.format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _parseDisplayTime(String raw) {
    try {
      final cleaned = raw.replaceAll('T', ' ');
      final parts = cleaned.split(' ');
      if (parts.length < 2) return '';
      final timePart = parts[1].split('.').first; // strip milliseconds
      final dt = DateFormat('HH:mm:ss').parse(timePart);
      return _timeFmt.format(dt);
    } catch (_) {
      return '';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        title: Text('Recipes', style: TextStyle(color: AppColors.whiteColor)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabController.index == 0) {
                _fetchActiveRecipes();
              } else {
                _fetchHistoryForSelectedSite();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.whiteColor,
          unselectedLabelColor: AppColors.whiteColor,
          indicatorColor: AppColors.orangeColor,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'ACTIVE'),
            Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildActiveTab(), _buildHistoryTab()],
      ),
    );
  }

  // ── ACTIVE TAB ───────────────────────────────────────────────────────────

  Widget _buildActiveTab() {
    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        if (provider.loadingActive) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Error: ${provider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchActiveRecipes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.activeRecipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                SizedBox(height: 12),
                Text(
                  'No Active Recipes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          itemCount: provider.activeRecipes.length,
          itemBuilder: (context, index) {
            return _buildActiveCard(provider.activeRecipes[index]);
          },
        );
      },
    );
  }

  Widget _buildActiveCard(RecipeModel recipeModel) {
    final displayDate = _parseDisplayDate(recipeModel.insertionDate);
    final displayTime = _parseDisplayTime(recipeModel.insertionDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xffD9D9D9), // Light grey background like image
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Pin + Site Name
            Row(
              children: [
                Image.asset('assets/map_marker_red.png', width: 24, height: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recipeModel.siteName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.grey, thickness: 0.5),
            const SizedBox(height: 8),

            // Data Grid: 3 rows x 3 columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: Status, Irr Amnt, Evapo
                _dataColumn([
                  _dataItem('assets/status.png', recipeModel.status),
                  _dataItem(
                    'assets/i_amnt.png',
                    '${_fmt(recipeModel.irrigationAmount)} Ltr/m',
                  ),
                  _dataItem(
                    'assets/evapo.png',
                    '${_fmt(recipeModel.evapotranspiration)} mm',
                  ),
                ]),
                // Column 2: Clock (Date/Time), Irr Time, Temp
                _dataColumn([
                  _dataDateTimeItem(
                    'assets/clock.png',
                    displayDate,
                    displayTime,
                  ),
                  _dataItem(
                    'assets/i_time.png',
                    '${recipeModel.irrigationTime} Mins',
                  ),
                  _dataItem(
                    'assets/temp.png',
                    '${_fmt(recipeModel.temperature)} °C',
                  ),
                ]),
                // Column 3: Moisture, Refill, Rainfall
                _dataColumn([
                  _dataItem(
                    'assets/mc.png',
                    '${_fmt(recipeModel.moistureContent)} %',
                  ),
                  _dataItem(
                    'assets/refill.png',
                    '${_fmt(recipeModel.refillPoint)} %',
                  ),
                  _dataItem(
                    'assets/rain_fall.png',
                    '${_fmt(recipeModel.rainFall)} %',
                  ),
                ]),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.grey, thickness: 0.5),
            const SizedBox(height: 4),

            // Footer: View Site | Update Schedule
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Image.asset('assets/to_site.png', width: 28, height: 28),
                      const SizedBox(width: 6),
                      const Text(
                        'View Site',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Image.asset('assets/valvei.png', width: 28, height: 28),
                      const SizedBox(width: 6),
                      const Text(
                        'Update Schedule',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataColumn(List<Widget> items) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }

  Widget _dataItem(String assetPath, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 22, height: 22),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataDateTimeItem(String assetPath, String date, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(assetPath, width: 22, height: 22),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HISTORY TAB ──────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return Consumer2<RecipeProvider, SiteProvider>(
      builder: (context, recipeProvider, siteProvider, _) {
        // Build unique site name list from SiteProvider
        final siteNames = siteProvider.sites
            .map((s) => s.siteName)
            .toSet()
            .toList();

        // Auto-select first site if nothing selected yet
        if (_selectedHistorySite == null && siteNames.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedHistorySite = siteNames.first);
              // Fetch only if we're already on the history tab
              if (_tabController.index == 1) _fetchHistoryForSelectedSite();
            }
          });
        }

        return Column(
          children: [
            // Site selector row (mirrors Android Spinner + ◀ ▶ buttons)
            _buildSiteSelector(siteNames),
            const Divider(height: 1),
            Expanded(
              child: recipeProvider.loadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : recipeProvider.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Error: ${recipeProvider.errorMessage}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchHistoryForSelectedSite,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : recipeProvider.processedHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'No history found',
                        style: TextStyle(color: AppColors.whiteColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      itemCount: recipeProvider.processedHistory.length,
                      itemBuilder: (ctx, i) =>
                          _buildHistoryCard(recipeProvider.processedHistory[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSiteSelector(List<String> siteNames) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          // Left arrow button
          _arrowButton(
            icon: Icons.chevron_left,
            enabled:
                siteNames.isNotEmpty &&
                _selectedHistorySite != null &&
                siteNames.indexOf(_selectedHistorySite!) > 0,
            onTap: () {
              if (_selectedHistorySite == null) return;
              final idx = siteNames.indexOf(_selectedHistorySite!);
              if (idx > 0) {
                setState(() => _selectedHistorySite = siteNames[idx - 1]);
                _fetchHistoryForSelectedSite();
              }
            },
          ),
          const SizedBox(width: 6),
          // Dropdown
          Expanded(
            child: siteNames.isEmpty
                ? const Text(
                    'No sites available',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  )
                : DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value:
                            _selectedHistorySite != null &&
                                siteNames.contains(_selectedHistorySite)
                            ? _selectedHistorySite
                            : null,
                        isExpanded: true,
                        hint: const Text('Select site'),
                        items: siteNames
                            .map(
                              (name) => DropdownMenuItem(
                                value: name,
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedHistorySite = val);
                          _fetchHistoryForSelectedSite();
                        },
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          // Right arrow button
          _arrowButton(
            icon: Icons.chevron_right,
            enabled:
                siteNames.isNotEmpty &&
                _selectedHistorySite != null &&
                siteNames.indexOf(_selectedHistorySite!) < siteNames.length - 1,
            onTap: () {
              if (_selectedHistorySite == null) return;
              final idx = siteNames.indexOf(_selectedHistorySite!);
              if (idx < siteNames.length - 1) {
                setState(() => _selectedHistorySite = siteNames[idx + 1]);
                _fetchHistoryForSelectedSite();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: enabled ? Colors.blueGrey : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildHistoryCard(ProcessedHistoryEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xffD9D9D9),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Row(
              children: [
                Image.asset('assets/clock.png', width: 22, height: 22),
                const SizedBox(width: 8),
                Text(
                  entry.date,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.grey, thickness: 0.5),
            const SizedBox(height: 8),

            // Data Grid: 2 rows (History only shows some fields in Android)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: Irr Amount, Evapo
                _dataColumn([
                  _dataItem(
                    'assets/i_amnt.png',
                    '${_fmt(entry.avgIrrigationAmount)} Ltrs',
                  ),
                  _dataItem(
                    'assets/evapo.png',
                    '${_fmt(entry.avgEvapotranspiration)} mm',
                  ),
                ]),
                // Column 2: Refill, Temp
                _dataColumn([
                  _dataItem(
                    'assets/refill.png',
                    '${_fmt(entry.avgRefillPoint)} %',
                  ),
                  _dataItem(
                    'assets/temp.png',
                    '${_fmt(entry.avgTemperature)} °C',
                  ),
                ]),
                // Column 3: Moisture, Rainfall
                _dataColumn([
                  _dataItem('assets/mc.png', '${_fmt(entry.avgMoisture)} %'),
                  _dataItem(
                    'assets/rain_fall.png',
                    '${_fmt(entry.avgRainFall)} %',
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
