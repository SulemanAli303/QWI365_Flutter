import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/site_provider.dart';
import '../providers/graph_provider.dart';
import '../providers/auth_provider.dart';
import '../models/historical_data_model.dart';

class GraphsScreen extends StatefulWidget {
  const GraphsScreen({super.key});

  @override
  State<GraphsScreen> createState() => _GraphsScreenState();
}

class _GraphsScreenState extends State<GraphsScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};

  // Selected value displays
  String _mcValue = "";
  String _tempValue = "";
  String _ecValue = "";
  String _solarValue = "";
  String _humidityValue = "";
  String _pressureValue = "";
  String _phValue = "";
  String _rainfallValue = "";

  // Color palette for devices
  static const List<String> colorArray = [
    'FF6B6B',
    '4ECDC4',
    '45B7D1',
    'FFA07A',
    '98D8C8',
    'F7DC6F',
    'BB8FCE',
    '85C1E9',
  ];

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  void _setDefaultDates() {
    _toDate = DateTime.now();
    _fromDate = DateTime.now();
  }

  void _fetchData() async {
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    final graphProvider = Provider.of<GraphProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = authProvider.username;

    if (siteProvider.selectedSiteName != null && username != null) {
      final Map<String, String> deviceTypeMap = {
        for (var site in siteProvider.sites)
          if (site.deviceName != null && site.deviceType != null)
            site.deviceName!: site.deviceType!,
      };

      try {
        await graphProvider.fetchHistoricalGraph(
          siteProvider.selectedSiteName!,
          _dateFormat.format(_fromDate),
          _dateFormat.format(_toDate),
          username,
          deviceTypeMap,
        );
        _updateMapMarker();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading graph data: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _updateMapMarker() {
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    if (siteProvider.sites.isEmpty) return;

    final selectedSite = siteProvider.sites.firstWhere(
      (s) => s.siteName == siteProvider.selectedSiteName,
      orElse: () => siteProvider.sites.first,
    );

    final position = LatLng(selectedSite.latitude, selectedSite.longitude);
    final marker = Marker(
      markerId: const MarkerId('selected_site'),
      position: position,
    );

    setState(() {
      _markers[marker.markerId] = marker;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 16.5));
  }

  @override
  Widget build(BuildContext context) {
    final graphProvider = Provider.of<GraphProvider>(context);
    final siteProvider = Provider.of<SiteProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Graphs'),
        backgroundColor: const Color(0xff333333),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: Column(
        children: [
          _buildSiteSelector(siteProvider),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'MAP VIEW',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _buildMapView(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      'GRAPHS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _buildDateSelectors(),
                  const SizedBox(height: 16),
                  graphProvider.loading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildGraphList(graphProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteSelector(SiteProvider siteProvider) {
    final currentIndex = siteProvider.sites.isEmpty
        ? 0
        : siteProvider.sites.indexWhere(
            (s) => s.siteName == siteProvider.selectedSiteName,
          );

    final isLeftEnabled = currentIndex > 0;
    final isRightEnabled = currentIndex < siteProvider.sites.length - 1;

    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black,
      child: Row(
        children: [
          _buildRoundButton(
            icon: Icons.chevron_left,
            onTap: isLeftEnabled ? () => _navigateSite(siteProvider, -1) : null,
            enabled: isLeftEnabled,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: siteProvider.selectedSiteName,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  items: siteProvider.sites.map((site) {
                    return DropdownMenuItem(
                      value: site.siteName,
                      child: Text(
                        site.siteName,
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    siteProvider.setSelectedSite(value);
                    _fetchData();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildRoundButton(
            icon: Icons.chevron_right,
            onTap: isRightEnabled ? () => _navigateSite(siteProvider, 1) : null,
            enabled: isRightEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 35,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey[700],
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, color: enabled ? Colors.black : Colors.grey[400]),
      ),
    );
  }

  void _navigateSite(SiteProvider provider, int offset) {
    if (provider.sites.isEmpty) return;
    final currentIndex = provider.sites.indexWhere(
      (s) => s.siteName == provider.selectedSiteName,
    );
    int nextIndex = currentIndex + offset;
    if (nextIndex >= 0 && nextIndex < provider.sites.length) {
      provider.setSelectedSite(provider.sites[nextIndex].siteName);
      _fetchData();
    }
  }

  Widget _buildMapView() {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(-28.8295, 132.4331),
          zoom: 3.3,
        ),
        markers: Set<Marker>.of(_markers.values),
        onMapCreated: (controller) {
          _mapController = controller;
          _updateMapMarker();
        },
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }

  Widget _buildDateSelectors() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _dateButton(_fromDate, true),
          _dateButton(_toDate, false),
        ],
      ),
    );
  }

  Widget _dateButton(DateTime date, bool isFrom) {
    return InkWell(
      onTap: () => _selectDate(context, isFrom),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xffD9D9D9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dateFormat.format(date),
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.black,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _fetchData();
    }
  }

  Widget _buildGraphList(GraphProvider graphProvider) {
    final hasData = graphProvider.graphData.values.any((list) => list.isNotEmpty);

    if (!hasData) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            _GraphHeader(title: 'MOISTURE CONTENT', icon: 'assets/mc.png'),
            const SizedBox(height: 100),
            const Center(
              child: Text(
                'No data found.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (graphProvider.graphData['Moisture']?.isNotEmpty ?? false)
            _buildGraphCard(
              'MOISTURE CONTENT',
              graphProvider.graphData['Moisture']!,
              'assets/mc.png',
              '%',
              0,
              (value) => setState(() => _mcValue = value),
            ),
          if (graphProvider.graphData['Temperature']?.isNotEmpty ?? false)
            _buildGraphCard(
              'TEMPERATURE',
              graphProvider.graphData['Temperature']!,
              'assets/temp.png',
              '℃',
              1,
              (value) => setState(() => _tempValue = value),
            ),
          if (graphProvider.graphData['EC']?.isNotEmpty ?? false)
            _buildGraphCard(
              'ELECTRICAL CONDUCTIVITY',
              graphProvider.graphData['EC']!,
              'assets/ec_30.png',
              'dS/m',
              2,
              (value) => setState(() => _ecValue = value),
            ),
          if (graphProvider.graphData['Solar']?.isNotEmpty ?? false)
            _buildGraphCard(
              'SOLAR RADIATION',
              graphProvider.graphData['Solar']!,
              'assets/solar30.png',
              'W/m²',
              3,
              (value) => setState(() => _solarValue = value),
            ),
          if (graphProvider.graphData['Humidity']?.isNotEmpty ?? false)
            _buildGraphCard(
              'HUMIDITY',
              graphProvider.graphData['Humidity']!,
              'assets/r_humid30.png',
              '%',
              4,
              (value) => setState(() => _humidityValue = value),
            ),
          if (graphProvider.graphData['Pressure']?.isNotEmpty ?? false)
            _buildGraphCard(
              'PRESSURE',
              graphProvider.graphData['Pressure']!,
              'assets/b_pressure30.png',
              'hPa',
              5,
              (value) => setState(() => _pressureValue = value),
            ),
          if (graphProvider.graphData['PH']?.isNotEmpty ?? false)
            _buildGraphCard(
              'PH',
              graphProvider.graphData['PH']!,
              'assets/ph30.png',
              'pH',
              6,
              (value) => setState(() => _phValue = value),
            ),
          if (graphProvider.graphData['Rainfall']?.isNotEmpty ?? false)
            _buildGraphCard(
              'RAINFALL',
              graphProvider.graphData['Rainfall']!,
              'assets/rain30.png',
              'mm',
              7,
              (value) => setState(() => _rainfallValue = value),
            ),
        ],
      ),
    );
  }

  Widget _buildGraphCard(
    String title,
    List<HistoricalDataModel> data,
    String icon,
    String unit,
    int typeIndex,
    Function(String) onValueSelected,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Group data by device name for legend
    final deviceGroups = <String, List<HistoricalDataModel>>{};
    for (var item in data) {
      deviceGroups.putIfAbsent(item.deviceName, () => []).add(item);
    }

    final devices = deviceGroups.keys.toList();
    String displayValue = _getDisplayValue(typeIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GraphHeader(title: title, icon: icon),
        const SizedBox(height: 16),
        // Display selected value
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            displayValue,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        // Chart
        SizedBox(
          height: 250,
          child: _buildLineChart(data, devices, typeIndex),
        ),
        // Legend
        const SizedBox(height: 16),
        _buildLegend(devices),
        const SizedBox(height: 24),
      ],
    );
  }

  String _getDisplayValue(int typeIndex) {
    switch (typeIndex) {
      case 0:
        return _mcValue;
      case 1:
        return _tempValue;
      case 2:
        return _ecValue;
      case 3:
        return _solarValue;
      case 4:
        return _humidityValue;
      case 5:
        return _pressureValue;
      case 6:
        return _phValue;
      case 7:
        return _rainfallValue;
      default:
        return "";
    }
  }

  Widget _buildLineChart(
    List<HistoricalDataModel> data,
    List<String> devices,
    int typeIndex,
  ) {
    // Group data by device
    final deviceGroups = <String, List<HistoricalDataModel>>{};
    for (var item in data) {
      deviceGroups.putIfAbsent(item.deviceName, () => []).add(item);
    }

    // Create line data sets for each device
    final lineDatSets = <LineChartBarData>[];

    for (int i = 0; i < devices.length; i++) {
      final deviceData = deviceGroups[devices[i]] ?? [];
      final spots = <FlSpot>[];

      for (int j = 0; j < deviceData.length; j++) {
        spots.add(FlSpot(j.toDouble(), deviceData[j].bus1Reading));
      }

      final color = _hexToColor(colorArray[i % colorArray.length]);

      lineDatSets.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 1.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(radius: 2, color: color),
          ),
          isStrokeCapRound: true,
        ),
      );
    }

    // Add refill line if moisture chart
    if (typeIndex == 0 && data.isNotEmpty && data.first.refillPoint != null) {
      final refillValue = data.first.refillPoint!;
      final spots = List.generate(
        data.length,
        (index) => FlSpot(index.toDouble(), refillValue),
      );

      lineDatSets.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: Colors.blue,
          barWidth: 1,
          dotData: const FlDotData(show: false),
          isStrokeCapRound: true,
        ),
      );
    }

    return LineChart(
      LineChartData(
        backgroundColor: Colors.black,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: null,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatYAxisValue(value),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey, width: 0.5),
        ),
        lineBarsData: lineDatSets,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response != null &&
                response.lineBarSpots != null &&
                response.lineBarSpots!.isNotEmpty) {
              _onChartValueSelected(response, typeIndex, devices);
            }
          },
        ),
      ),
    );
  }

  void _onChartValueSelected(
    LineTouchResponse response,
    int typeIndex,
    List<String> devices,
  ) {
    if (response.lineBarSpots == null || response.lineBarSpots!.isEmpty) return;

    final spot = response.lineBarSpots!.first;
    final value = spot.y;

    String unit = '';
    String prefix = '';

    switch (typeIndex) {
      case 0:
        unit = '%';
        break;
      case 1:
        unit = ' ℃';
        break;
      case 2:
        unit = ' dS/m';
        break;
      case 3:
        unit = ' W/m²';
        break;
      case 4:
        unit = ' %';
        break;
      case 5:
        unit = ' hPa';
        break;
      case 6:
        prefix = 'pH ';
        unit = '';
        break;
      case 7:
        unit = ' mm';
        break;
    }

    final formattedValue = _getDecimalString(value, value % 1 == 0 ? '0' : '1');
    setState(() {
      final displayText = '$prefix$formattedValue$unit';
      switch (typeIndex) {
        case 0:
          _mcValue = displayText;
          break;
        case 1:
          _tempValue = displayText;
          break;
        case 2:
          _ecValue = displayText;
          break;
        case 3:
          _solarValue = displayText;
          break;
        case 4:
          _humidityValue = displayText;
          break;
        case 5:
          _pressureValue = displayText;
          break;
        case 6:
          _phValue = displayText;
          break;
        case 7:
          _rainfallValue = displayText;
          break;
      }
    });
  }

  String _formatYAxisValue(double value) {
    if ((value % 1) == 0) {
      return value.toStringAsFixed(0);
    } else {
      return value.toStringAsFixed(1);
    }
  }

  String _getDecimalString(double value, String decimal) {
    final decimalPlaces = int.parse(decimal);
    return value.toStringAsFixed(decimalPlaces);
  }

  Widget _buildLegend(List<String> devices) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (int i = 0; i < devices.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _hexToColor(colorArray[i % colorArray.length]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                devices[i],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
      ],
    );
  }

  Color _hexToColor(String hexColor) {
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}

class _GraphHeader extends StatelessWidget {
  final String title;
  final String icon;

  const _GraphHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(icon, width: 28, height: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
