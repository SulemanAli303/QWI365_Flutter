import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:water365/controllers/params_controller.dart';
import 'package:water365/controllers/sites_controller.dart';
import 'package:water365/utils/app_colors.dart';
import 'package:water365/utils/water_quality_calculator.dart';
import 'package:intl/intl.dart';

class ParamsScreen extends StatelessWidget {
  const ParamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ParamsController());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          controller.paramName
              .toLowerCase()
              .split(' ')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' '),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final sitesController = Get.find<SitesController>();
        if (sitesController.isDataLoading.value &&
            controller.parameters.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryOrange),
          );
        }

        return Column(
          children: [
            _buildSummaryHeader(controller),
            Expanded(
              child: controller.parameters.isEmpty
                  ? const Center(
                      child: Text(
                        "No records found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      itemCount: controller.parameters.length,
                      itemBuilder: (context, index) {
                        return _buildParameterRow(controller.parameters[index]);
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSummaryHeader(ParamsController controller) {
    final assessment = controller.assessment.value;
    if (assessment == null) return const SizedBox();

    String displayTime = "00:00 AM";
    String displayDate = "01 Jan 2024";

    try {
      if (controller.site.lastUpdate.isNotEmpty) {
        DateTime dt = DateTime.parse(controller.site.lastUpdate);
        displayTime = DateFormat('hh:mm a').format(dt);
        displayDate = DateFormat('dd MMM yyyy').format(dt);
      }
    } catch (e) {
      displayTime = DateFormat('hh:mm a').format(DateTime.now());
      displayDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    }

    Color potabilityColor;
    switch (assessment.statusColor) {
      case WaterQualityStatus.good:
        potabilityColor = const Color(0xFF33D940);
        break;
      case WaterQualityStatus.warning:
        potabilityColor = const Color(0xFFEFFF00);
        break;
      case WaterQualityStatus.danger:
        potabilityColor = const Color(0xFFFF0000);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 20),
              Container(height: 50, width: 1.5, color: Colors.white70),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayDate,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        controller.site.siteName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            "Conformance to BIS Specification IS10500: ${assessment.conformancePercentage.toStringAsFixed(1)}%",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            assessment.potabilityStatus,
            style: TextStyle(
              color: potabilityColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildParameterRow(ParameterData data) {
    final controller = Get.find<ParamsController>();
    Color dotColor;
    if (data.status == WaterQualityStatus.good)
      dotColor = AppColors.dotGreen;
    else if (data.status == WaterQualityStatus.warning)
      dotColor = AppColors.dotYellow;
    else
      dotColor = AppColors.dotRed;

    return InkWell(
      onTap: () {
        controller.fetchHistory(data.key);
        _showHistoryChart(data);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                data.name,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(
              width: 50,
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  data.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryChart(ParameterData data) {
    final controller = Get.find<ParamsController>();
    Get.bottomSheet(
      Container(
        height: 350,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Text(
              "${data.name} History",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Obx(() {
                if (controller.isHistoryLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  );
                }

                if (controller.historyPoints.isEmpty) {
                  return const Center(
                    child: Text(
                      "No historical data found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (val, _) => Text(
                            val.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: controller.historyPoints,
                        isCurved: true,
                        color: AppColors.primaryOrange,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primaryOrange.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
