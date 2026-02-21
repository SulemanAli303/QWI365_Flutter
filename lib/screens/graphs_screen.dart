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
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  void _fetchData() {
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

      graphProvider.fetchHistoricalGraph(
        siteProvider.selectedSiteName!,
        _dateFormat.format(_fromDate),
        _dateFormat.format(_toDate),
        username,
        deviceTypeMap,
      );
      _updateMapMarker();
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
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          _squareArrowButton(
            icon: Icons.chevron_left,
            onPressed: () => _navigateSite(siteProvider, -1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xffD9D9D9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: siteProvider.selectedSiteName,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black,
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  dropdownColor: const Color(0xffD9D9D9),
                  items: siteProvider.sites.map((site) {
                    return DropdownMenuItem(
                      value: site.siteName,
                      child: Text(site.siteName),
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
          const SizedBox(width: 8),
          _squareArrowButton(
            icon: Icons.chevron_right,
            onPressed: () => _navigateSite(siteProvider, 1),
          ),
        ],
      ),
    );
  }

  Widget _squareArrowButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 45,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xff444444),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.black, size: 30),
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
        children: [_dateButton(_fromDate, true), _dateButton(_toDate, false)],
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
    if (graphProvider.graphData.values.every((list) => list.isEmpty)) {
      return const Column(
        children: [
          _GraphHeader(title: 'MOISTURE CONTENT'),
          SizedBox(height: 100),
          Center(
            child: Text(
              'No data found.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (graphProvider.graphData['Moisture']?.isNotEmpty ?? false)
          _buildGraphCard(
            'MOISTURE CONTENT',
            graphProvider.graphData['Moisture']!,
            Colors.blue,
            '%',
          ),
        if (graphProvider.graphData['Temperature']?.isNotEmpty ?? false)
          _buildGraphCard(
            'TEMPERATURE',
            graphProvider.graphData['Temperature']!,
            Colors.red,
            '℃',
          ),
        // ... (other categories would go here if needed)
      ],
    );
  }

  Widget _buildGraphCard(
    String title,
    List<HistoricalDataModel> data,
    Color color,
    String unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GraphHeader(title: title),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.black,
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: data
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                      .toList(),
                  isCurved: false,
                  color: color,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (data.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              '${data.last.value.toStringAsFixed(1)} $unit @ ${data.last.dateTime}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _GraphHeader extends StatelessWidget {
  final String title;
  const _GraphHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/mc.png', width: 28, height: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
