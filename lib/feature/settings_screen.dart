import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water365/controllers/settings_controller.dart';
import 'package:water365/utils/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildUserSection(controller),
          const SizedBox(height: 30),
          _buildSettingItem(
            title: "Default Map Layer",
            value: controller.mapMode,
            options: ["Satellite", "Normal"],
            onChanged: (val) => controller.updateMapMode(val!),
          ),
          const SizedBox(height: 25),
          _buildSettingItem(
            title: "Default Site",
            value: controller.defSite,
            options: [
              "ATP-Dhantalapalli",
              "ATP-Gadakal-60",
              "ATP-Garladinne-60K",
              ...controller.sites
                  .map((s) => s.siteName)
                  .where(
                    (s) => ![
                      "ATP-Dhantalapalli",
                      "ATP-Gadakal-60",
                      "ATP-Garladinne-60K",
                    ].contains(s),
                  ),
            ],
            onChanged: (val) => controller.updateDefaultSite(val!),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection(SettingsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Image.asset('assets/account.png', width: 40, height: 40),
          const SizedBox(width: 15),
          Obx(
            () => Text(
              controller.username.value,
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required RxString value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.secondaryTextColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: options.contains(value.value)
                    ? value.value
                    : options.first,
                dropdownColor: AppColors.lightGrey,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                items: options.map((String opt) {
                  return DropdownMenuItem<String>(value: opt, child: Text(opt));
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
