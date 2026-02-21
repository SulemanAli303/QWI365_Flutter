import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qwi365/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/site_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _mapType = 'Normal';
  String? _defaultSite;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      _mapType = pref.getString('mapLayer') == 'sat' ? 'Satellite' : 'Normal';
      _defaultSite = pref.getString('defSite');
    });
  }

  void _saveMapType(String type) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('mapLayer', type == 'Satellite' ? 'sat' : 'normal');
    setState(() {
      _mapType = type;
    });
  }

  void _saveDefaultSite(String? site) async {
    final pref = await SharedPreferences.getInstance();
    if (site != null) {
      await pref.setString('defSite', site);
    }
    setState(() {
      _defaultSite = site;
    });
  }

  @override
  Widget build(BuildContext context) {
    final siteProvider = Provider.of<SiteProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgColor, // Match light background in image
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.bgColor,
        foregroundColor: AppColors.whiteColor,
      ),
      body: ListView(
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.whiteColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    authProvider.username ?? 'N/A',
                    style: const TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: _buildDropdownSection(
              label: 'Default Map Layer',
              value: _mapType,
              items: ['Normal', 'Satellite'],
              onChanged: (val) {
                if (val != null) _saveMapType(val);
              },
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: _buildDropdownSection(
              label: 'Default Site',
              value: siteProvider.sites.any((s) => s.siteName == _defaultSite)
                  ? _defaultSite
                  : null,
              items: siteProvider.sites.map((s) => s.siteName).toList(),
              hint: 'Select Site',
              onChanged: (val) {
                if (val != null) _saveDefaultSite(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection({
    required String label,
    required String? value,
    required List<String> items,
    String? hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xffE0E0E0), // Grey background like in image
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (value != null && items.contains(value)) ? value : null,
              hint: hint != null ? Text(hint) : null,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
              isExpanded: true,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              items: items.map((String val) {
                return DropdownMenuItem<String>(value: val, child: Text(val));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
