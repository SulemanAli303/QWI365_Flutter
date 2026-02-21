import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:qwi365/utils/app_colors.dart';
import '../models/site_model.dart';
import '../providers/site_provider.dart';
import '../providers/auth_provider.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  late BitmapDescriptor _redMarker;
  late BitmapDescriptor _greenMarker;
  late BitmapDescriptor _yellowMarker;
  late BitmapDescriptor _blueMarker;
  GoogleMapController? _mapController;
  bool _markersLoaded = false;

  void _loadMarkerIcons() async {
    _redMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(32, 32)),
      'assets/map_marker_red.png',
    );
    _greenMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(32, 32)),
      'assets/map_marker_green.png',
    );
    _yellowMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(32, 32)),
      'assets/map_marker_yellow.png',
    );
    _blueMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(32, 32)),
      'assets/map_marker_blue.png',
    );
    if (mounted) {
      setState(() {
        _markersLoaded = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final siteProvider = Provider.of<SiteProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final username = authProvider.username;

      if (username != null) {
        if (siteProvider.sites.isEmpty) {
          siteProvider.fetchSites(username).then((_) {
            if (siteProvider.sites.isNotEmpty) {
              final firstSite = siteProvider.sites.first;
              _onSiteSelected(firstSite.siteName, username, moveCamera: true);
            }
          });
        } else if (siteProvider.selectedSiteName == null) {
          final firstSite = siteProvider.sites.first;
          _onSiteSelected(firstSite.siteName, username, moveCamera: true);
        } else {
          _fetchData(context, siteProvider.selectedSiteName!, username);
          // Camera move will happen on next frame if controller is ready
        }
      }
    });
  }

  void _onSiteSelected(
    String siteName,
    String username, {
    bool moveCamera = true,
  }) {
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    siteProvider.setSelectedSite(siteName);
    _fetchData(context, siteName, username);

    if (moveCamera) {
      final site = siteProvider.sites.firstWhere(
        (element) => element.siteName == siteName,
      );
      _animateToSite(site.latitude, site.longitude);
    }
  }

  void _animateToSite(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.5),
    );
  }

  void _fetchData(BuildContext context, String siteName, String username) {
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    siteProvider.fetchDeviceDetails(siteName, username);
    siteProvider.fetchAvailableWater(siteName);
  }

  @override
  Widget build(BuildContext context) {
    final siteProvider = Provider.of<SiteProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Get the first site with matching name (to use for map and data)
    final selectedSite = siteProvider.sites.firstWhere(
      (s) => s.siteName == siteProvider.selectedSiteName,
      orElse: () => siteProvider.sites.isNotEmpty
          ? siteProvider.sites.first
          : SiteModel(siteName: '', latitude: 0, longitude: 0),
    );

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        title: const Text('Sites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (siteProvider.loading)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: CupertinoActivityIndicator(
                color: Colors.white,
                radius: 15,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSiteSelector(siteProvider, authProvider.username),
          Expanded(
            child: ListView(
              children: [
                _buildSectionHeader('MAP VIEW'),
                _buildMapSection(selectedSite),
                _buildSectionHeader('READILY AVAILABLE WATER'),
                _buildAvailableWaterSection(siteProvider),
                _buildSectionHeader('DEVICE LIST'),
                _buildDeviceList(siteProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSiteSelector(SiteProvider siteProvider, String? username) {
    // Sites are already deduplicated in SiteProvider
    final index = siteProvider.sites.indexWhere(
      (s) => s.siteName == siteProvider.selectedSiteName,
    );
    final isFirst = index <= 0;
    final isLast = index >= siteProvider.sites.length - 1;

    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black,
      child: Row(
        children: [
          _buildRoundButton(
            icon: Icons.chevron_left,
            onTap: isFirst || username == null
                ? null
                : () {
                    final newSite = siteProvider.sites[index - 1].siteName;
                    _onSiteSelected(newSite, username);
                  },
            enabled: !isFirst && username != null,
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
                  onChanged: (val) {
                    if (val != null && username != null) {
                      _onSiteSelected(val, username);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildRoundButton(
            icon: Icons.chevron_right,
            onTap: isLast || username == null
                ? null
                : () {
                    final newSite = siteProvider.sites[index + 1].siteName;
                    _onSiteSelected(newSite, username);
                  },
            enabled: !isLast && username != null,
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
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

  Widget _buildAvailableWaterSection(SiteProvider provider) {
    final water = provider.waterModel;
    if (water == null) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text(
            "No data found.",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    double dFc = water.fieldCapacity;
    double dRf = water.refillPoint;
    double dWp = water.wiltingPoint;
    double dMc = water.moistureContent;

    if (dFc == 0) dFc = dRf + 10.0;
    if (dWp == 0) dWp = dRf - 10.0;

    double diff = dFc - dWp;
    double avg = diff / 10;

    double v1 = dWp + avg;
    double v2_5 = dWp + (avg * 2.5);
    double v3 = dWp + (avg * 3);
    double v3_5 = dWp + (avg * 3.5);
    double v4 = dWp + (avg * 4);
    double v5 = dWp + (avg * 5);
    double v6 = dWp + (avg * 6);
    double v7 = dWp + (avg * 7);
    double v7_5 = dWp + (avg * 7.5);
    double v8 = dWp + (avg * 8);
    double v9 = dWp + (avg * 9);
    double v10 = dWp + (avg * 10);

    String dropletAsset = 'assets/d5.png';
    if (dMc < v1) {
      dropletAsset = 'assets/d1.png';
    } else if (dMc < v2_5) {
      dropletAsset = 'assets/d2.png';
    } else if (dMc < v3) {
      dropletAsset = 'assets/d2_5.png';
    } else if (dMc < v3_5) {
      dropletAsset = 'assets/d3.png';
    } else if (dMc < v4) {
      dropletAsset = 'assets/d3_5.png';
    } else if (dMc < v5) {
      dropletAsset = 'assets/d4.png';
    } else if (dMc < v6) {
      dropletAsset = 'assets/d5.png';
    } else if (dMc < v7) {
      dropletAsset = 'assets/d6.png';
    } else if (dMc < v7_5) {
      dropletAsset = 'assets/d7.png';
    } else if (dMc < v8) {
      dropletAsset = 'assets/d7_5.png';
    } else if (dMc < v9) {
      dropletAsset = 'assets/d8.png';
    } else if (dMc < v10) {
      dropletAsset = 'assets/d9.png';
    } else {
      dropletAsset = 'assets/d10.png';
    }

    return SizedBox(
      height: 340,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double dropW = 110.0;
          final double dropH = 210.0;
          final double cx = constraints.maxWidth / 2;
          final double dropLeft = cx - dropW / 2;
          final double dropRight = cx + dropW / 2;
          // Center of the droplet vertically: top=20, height=210 → center at 20 + 105 = 125
          final double dropTop = 20.0;
          final double dropCenterY = dropTop + dropH / 2; // ~125

          return Stack(
            children: [
              // ── Droplet image ──────────────────────────────
              Positioned(
                left: dropLeft,
                top: dropTop,
                child: Image.asset(
                  dropletAsset,
                  width: dropW,
                  height: dropH,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.water_drop,
                    size: 70,
                    color: Colors.blue,
                  ),
                ),
              ),

              // ── Horizontal center dashed line across drop ──
              Positioned(
                left: dropLeft + 12,
                top: dropCenterY,
                child: SizedBox(
                  width: dropW - 25,
                  height: 3,
                  child: CustomPaint(
                    painter: _DashedLinePainter(Colors.white60),
                  ),
                ),
              ),

              // ── Field Capacity — top right, with dashed line ──
              Positioned(
                top: dropTop - 5,
                right: 18,
                child: _buildLabelWithDash(
                  label: 'Field Capacity',
                  value: dFc,
                  dashWidth: (constraints.maxWidth - dropRight - 8).clamp(
                    20.0,
                    90.0,
                  ),
                  leading: true,
                  paddingWidth: 6,
                ),
              ),

              // ── Wilting Point — bottom right, with dashed line ──
              Positioned(
                bottom: 110,
                right: 25,
                child: _buildLabelWithDash(
                  label: 'Wilting Point',
                  value: dWp,
                  dashWidth: (constraints.maxWidth - dropRight - 8).clamp(
                    20.0,
                    90.0,
                  ),
                  leading: true,
                  paddingWidth: 6,
                ),
              ),

              // ── Refill Point — left side, plain label only ──
              Positioned(
                top: dropCenterY - 26,
                left: 30,
                child: _buildPlainLabel(
                  label: 'Refill Point',
                  value: dRf,
                  align: CrossAxisAlignment.end,
                ),
              ),

              // ── Moisture Avg — right side middle, plain label only ──
              Positioned(
                top: dropCenterY - 26,
                right: 20,
                child: _buildPlainLabel(
                  label: 'Moisture Avg.',
                  value: dMc,
                  align: CrossAxisAlignment.start,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlainLabel({
    required String label,
    required double value,
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        Text(
          '${value.toStringAsFixed(1)} %',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLabelWithDash({
    required String label,
    required double value,
    required double dashWidth,
    required double paddingWidth,
    required bool
    leading, // true = label on right (dash then label), false = label on left
  }) {
    final labelWidget = Column(
      crossAxisAlignment: leading
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.whiteColor, fontSize: 12),
        ),
        Text(
          '${value.toStringAsFixed(1)} %',
          style: const TextStyle(
            color: AppColors.whiteColor,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );

    final dash = SizedBox(
      width: dashWidth.clamp(20.0, 80.0),
      child: CustomPaint(painter: _DashedLinePainter(AppColors.whiteColor)),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: leading
          ? [dash, SizedBox(width: paddingWidth), labelWidget]
          : [labelWidget, SizedBox(width: 9), dash],
    );
  }

  Widget _buildDeviceList(SiteProvider siteProvider) {
    if (siteProvider.devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30.0),
        child: Center(
          child: Text(
            'No devices found',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: siteProvider.devices.length,
      itemBuilder: (context, index) {
        final device = siteProvider.devices[index];

        // Determine moisture value color relative to refill point
        final mc = device.bus1Reading;
        final rf = device.refillPoint;
        Color mcColor = Colors.red;
        if (mc >= rf - 0.75 && mc <= rf + 1.0) {
          mcColor = Colors.green;
        } else if (mc > rf + 1.0) {
          mcColor = const Color(0xFFFF9800); // orange
        }

        return Card(
          color: const Color(0xFFE0E0E0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: device name + date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        device.deviceName,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      device.insertionDate,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Bottom row: droplet icon + big moisture value
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/d5.png',
                      width: 30,
                      height: 30,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.water_drop, size: 26, color: mcColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${mc.toStringAsFixed(1)} %',
                      style: TextStyle(
                        color: mcColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapSection(SiteModel selectedSite) {
    if (selectedSite.siteName.isEmpty || !_markersLoaded) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    BitmapDescriptor icon = _blueMarker;
    double zIndex = 0;

    if (selectedSite.deviceType == "5TE" ||
        selectedSite.deviceType == "GS3" ||
        selectedSite.deviceType == "EnviroScan" ||
        selectedSite.deviceType == "5TM" ||
        selectedSite.deviceType == "10HS" ||
        selectedSite.deviceType == "GS1") {
      double mcVal = selectedSite.bus1Reading ?? 0.0;
      double reFillVal = selectedSite.refillPoint ?? 0.0;

      double lowStart = (reFillVal - 0.74) - 5.00;
      double lowEnd = reFillVal - 0.74;
      double idleStart = reFillVal - 0.75;
      double idleEnd = reFillVal + 1.00;
      double highStart = reFillVal + 1.01;
      double highEnd = (reFillVal + 1.01) + 5.00;

      if (mcVal >= lowStart && mcVal <= lowEnd) {
        icon = _redMarker;
        zIndex = 3;
      } else if (mcVal >= idleStart && mcVal <= idleEnd) {
        icon = _greenMarker;
        zIndex = 1;
      } else if (mcVal >= highStart && mcVal <= highEnd) {
        icon = _yellowMarker;
        zIndex = 2;
      } else {
        if (mcVal > reFillVal) {
          icon = _yellowMarker;
          zIndex = 2;
        } else {
          icon = _redMarker;
          zIndex = 3;
        }
      }
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        initialCameraPosition: CameraPosition(
          target: LatLng(selectedSite.latitude, selectedSite.longitude),
          zoom: 16.5,
        ),
        mapType: MapType.hybrid,
        markers: {
          Marker(
            markerId: MarkerId(selectedSite.siteName),
            position: LatLng(selectedSite.latitude, selectedSite.longitude),
            icon: icon,
            zIndex: zIndex,
          ),
        },
        zoomControlsEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }
}

// End of file

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
