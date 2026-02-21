import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:provider/provider.dart';
import 'package:qwi365/utils/app_colors.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/site_provider.dart';
import '../providers/recipe_provider.dart';
import '../utils/app_routes.dart';
import '../widgets/custom_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  final Set<Marker> _markers = {};
  bool _isInit = true;

  late BitmapDescriptor _redMarker;
  late BitmapDescriptor _greenMarker;
  late BitmapDescriptor _yellowMarker;
  late BitmapDescriptor _blueMarker;
  bool _markersLoaded = false;
  MapType _currentMapType = MapType.hybrid;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSites();
      _loadRecipes();
      // Start periodic refresh
      _startRefreshTimer();
    });
  }

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    super.dispose();
  }

  void _loadMarkerIcons() async {
    _redMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(120, 120)),
      'assets/map_marker_red.png',
    );
    _greenMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(120, 120)),
      'assets/map_marker_green.png',
    );
    _yellowMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(120, 120)),
      'assets/map_marker_yellow.png',
    );
    _blueMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(120, 120)),
      'assets/map_marker_blue.png',
    );
    setState(() {
      _markersLoaded = true;
    });
  }

  void _startRefreshTimer() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _loadSites();
        _loadRecipes();
        _startRefreshTimer();
      }
    });
  }

  void _loadSites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);

    if (authProvider.username != null) {
      await siteProvider.fetchSites(authProvider.username!);
      _updateMarkers(siteProvider);
    }
  }

  void _loadRecipes() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    if (authProvider.username != null) {
      try {
        await recipeProvider.fetchActiveRecipes(authProvider.username!);
      } catch (e) {
        debugPrint('Error fetching recipes: $e');
      }
    }
  }

  void _updateMarkers(SiteProvider siteProvider) {
    if (!_markersLoaded) return;

    setState(() {
      _markers.clear();
      for (var site in siteProvider.sites) {
        BitmapDescriptor icon = _blueMarker;
        double zIndex = 0;

        if (site.deviceType == "5TE" ||
            site.deviceType == "GS3" ||
            site.deviceType == "EnviroScan" ||
            site.deviceType == "5TM" ||
            site.deviceType == "10HS" ||
            site.deviceType == "GS1") {
          double mcVal = site.bus1Reading ?? 0.0;
          double reFillVal = site.refillPoint ?? 0.0;

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

        _markers.add(
          Marker(
            markerId: MarkerId(site.siteName),
            position: LatLng(site.latitude, site.longitude),
            icon: icon,
            zIndex: zIndex,
            onTap: () {
              _customInfoWindowController.addInfoWindow!(
                _buildInfoWindow(site),
                LatLng(site.latitude, site.longitude),
              );
            },
          ),
        );
      }

      if (_isInit && _markers.isNotEmpty) {
        _fitBounds();
        _isInit = false;
      }
    });
  }

  Widget _buildInfoWindow(dynamic site) {
    String dateTimeStr = site.lastUpdate ?? "N/A";
    try {
      if (site.lastUpdate != null) {
        DateFormat inputFormat = DateFormat("dd/MM/yyyy HH:mm:ss");
        DateTime dateTime = inputFormat.parse(site.lastUpdate!);
        dateTimeStr = DateFormat("dd MMM yy, hh:mm aa").format(dateTime);
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    String dType = site.deviceType ?? "";
    String bus1 = site.bus1Reading?.toStringAsFixed(1) ?? "0.0";
    String bus2 = site.bus2Reading?.toStringAsFixed(1) ?? "0.0";
    String bus3 = site.bus3Reading?.toStringAsFixed(1) ?? "0.0";
    String refill = site.refillPoint?.toStringAsFixed(1) ?? "0.0";

    List<Widget> rows = [];

    switch (dType) {
      case "5TE":
      case "GS3":
      case "EnviroScan":
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/mc28.png', '$bus1 %'),
              _buildInfoItem('assets/temp28.png', '$bus2 ℃'),
            ],
          ),
        );
        rows.add(const SizedBox(height: 5));
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/refill28.png', '$refill %'),
              _buildInfoItem('assets/ec28.png', '$bus3 dS/m'),
            ],
          ),
        );
        break;

      case "VP4":
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/temp_30.png', '$bus1 ℃'),
              _buildInfoItem(
                'assets/r_humid30.png',
                '${site.bus2Reading?.toStringAsFixed(0) ?? "0"} %',
              ),
            ],
          ),
        );
        rows.add(const SizedBox(height: 5));
        rows.add(
          Row(
            children: [
              _buildInfoItem(
                'assets/b_pressure30.png',
                '${site.bus3Reading?.toStringAsFixed(0) ?? "0"} hPa',
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
        break;

      case "5TM":
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/mc28.png', '$bus1 %'),
              _buildInfoItem('assets/temp28.png', '$bus2 ℃'),
            ],
          ),
        );
        rows.add(const SizedBox(height: 5));
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/refill28.png', '$refill %'),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
        break;

      case "10HS":
      case "GS1":
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/mc28.png', '$bus1 %'),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
        rows.add(const SizedBox(height: 5));
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/refill28.png', '$refill %'),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
        break;

      case "PYR":
        rows.add(
          Row(
            children: [
              _buildInfoItem(
                'assets/solar30.png',
                '${site.bus1Reading?.toStringAsFixed(0) ?? "0"} W/m\u00B2',
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
        break;

      case "EC":
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/ec_30.png', '$bus1 dS/m'),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
        break;

      case "PH":
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/ph30.png', 'pH $bus1'),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
        break;

      case "LWS":
        String lwsText = "Rainfall";
        double? lws = site.bus1Reading;
        if (lws == 1) {
          lwsText = "Dry";
        } else if (lws == 2) {
          lwsText = "Frost";
        } else if (lws == 3) {
          lwsText = "Dew";
        }
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/evapo30.png', lwsText),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
        break;

      case "ECRN50":
      case "ECRN100":
        rows.add(
          Row(
            children: [
              _buildInfoItem(
                'assets/rain30.png',
                '${site.bus1Reading?.toStringAsFixed(0) ?? "0"} mm',
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
        break;

      default:
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/mc28.png', '$bus1 %'),
              _buildInfoItem('assets/temp28.png', '$bus2 ℃'),
            ],
          ),
        );
        rows.add(const SizedBox(height: 5));
        rows.add(
          Row(
            children: [
              _buildInfoItem('assets/refill28.png', '$refill %'),
              _buildInfoItem('assets/ec28.png', '$bus3 dS/m'),
            ],
          ),
        );
    }

    return Container(
      width: 275,
      height: 165,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Image.asset('assets/site.png', width: 24, height: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        site.siteName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        site.deviceName ?? "",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFBDBDBD)),
          // Date Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Image.asset('assets/clock28.png', width: 20, height: 20),
                const SizedBox(width: 10),
                Text(
                  dateTimeStr,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                ),
              ],
            ),
          ),
          // Data Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(children: rows),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String iconAsset, String value) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconAsset, width: 20, height: 20),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (var m in _markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0,
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.hybrid
          ? MapType.normal
          : MapType.hybrid;
    });
  }

  void _askLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attention'),
        content: const Text('Logout App?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siteProvider = Provider.of<SiteProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        title: const Text(''),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.recipes),
            icon: Icon(
              Icons.info,
              color: recipeProvider.activeRecipes.isNotEmpty
                  ? Colors.red
                  : Colors.white,
            ),
          ),
          IconButton(onPressed: _askLogout, icon: const Icon(Icons.logout)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'map') {
                _toggleMapType();
              } else if (value == 'settings') {
                Navigator.pushNamed(context, AppRoutes.settings);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'map',
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Map layer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-28.8295, 132.4331),
              zoom: 3.3,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _customInfoWindowController.googleMapController = controller;
            },
            onTap: (position) {
              _customInfoWindowController.hideInfoWindow!();
            },
            onCameraMove: (position) {
              _customInfoWindowController.onCameraMove!();
            },
            markers: _markers,
            mapType: _currentMapType,
            myLocationButtonEnabled: false,
          ),
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: 165,
            width: 275,
            offset: 50,
          ),
          if (siteProvider.loading)
            Center(
              child: CircularProgressIndicator(color: AppColors.orangeColor),
            ),
        ],
      ),
    );
  }
}
