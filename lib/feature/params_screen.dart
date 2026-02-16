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
      PopScope(
        canPop: false, // Prevent back button dismissal
        child: Container(
          height: 450,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    "${data.name} History",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
                  onPressed: () {
                    final xRange = controller.maxX.value - controller.minX.value;
                    final yRange = controller.maxY.value - controller.minY.value;
                    final xCenter = (controller.minX.value + controller.maxX.value) / 2;
                    final yCenter = (controller.minY.value + controller.maxY.value) / 2;

                    controller.minX.value = xCenter - xRange * 0.35;
                    controller.maxX.value = xCenter + xRange * 0.35;
                    controller.minY.value = yCenter - yRange * 0.35;
                    controller.maxY.value = yCenter + yRange * 0.35;
                  },
                  tooltip: 'Zoom In',
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
                  onPressed: () {
                    final xRange = controller.maxX.value - controller.minX.value;
                    final yRange = controller.maxY.value - controller.minY.value;
                    final xCenter = (controller.minX.value + controller.maxX.value) / 2;
                    final yCenter = (controller.minY.value + controller.maxY.value) / 2;

                    final allX = controller.historyPoints.map((e) => e.x).toList();
                    final allY = controller.historyPoints.map((e) => e.y).toList();
                    final minPossibleX = allX.reduce((a, b) => a < b ? a : b);
                    final maxPossibleX = allX.reduce((a, b) => a > b ? a : b);
                    final minPossibleY = allY.reduce((a, b) => a < b ? a : b) * 0.9;
                    final maxPossibleY = allY.reduce((a, b) => a > b ? a : b) * 1.1;

                    controller.minX.value = (xCenter - xRange * 0.75).clamp(minPossibleX, maxPossibleX);
                    controller.maxX.value = (xCenter + xRange * 0.75).clamp(minPossibleX, maxPossibleX);
                    controller.minY.value = (yCenter - yRange * 0.75).clamp(minPossibleY, maxPossibleY);
                    controller.maxY.value = (yCenter + yRange * 0.75).clamp(minPossibleY, maxPossibleY);
                  },
                  tooltip: 'Zoom Out',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                  onPressed: () => controller.resetZoom(),
                  tooltip: 'Reset Zoom',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _ChartGestureWrapper(controller: controller),
            ),
          ],
        ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: false, // Prevent swipe down dismissal
      enableDrag: false, // Prevent drag to dismiss
    );
  }
}

class _ChartGestureWrapper extends StatefulWidget {
  final ParamsController controller;

  const _ChartGestureWrapper({required this.controller});

  @override
  State<_ChartGestureWrapper> createState() => _ChartGestureWrapperState();
}

class _ChartGestureWrapperState extends State<_ChartGestureWrapper> {
  double _baseScale = 1.0;
  bool _isMultiTouch = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.isHistoryLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryOrange,
          ),
        );
      }

      if (widget.controller.historyPoints.isEmpty) {
        return const Center(
          child: Text(
            "No historical data found",
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque, // Capture all gestures in the area
        onScaleStart: (details) {
          _baseScale = 1.0;
          _isMultiTouch = false;
        },
        onScaleUpdate: (details) {
          if (details.pointerCount == 2) {
            // Two-finger pinch zoom
            if (!_isMultiTouch) {
              setState(() {
                _isMultiTouch = true;
              });
            }
            final scale = details.scale;
            final scaleFactor = scale / _baseScale;
            _baseScale = scale;

            if ((scaleFactor - 1.0).abs() > 0.001) {
              final xRange = widget.controller.maxX.value - widget.controller.minX.value;
              final yRange = widget.controller.maxY.value - widget.controller.minY.value;
              final xCenter = (widget.controller.minX.value + widget.controller.maxX.value) / 2;
              final yCenter = (widget.controller.minY.value + widget.controller.maxY.value) / 2;

              final allX = widget.controller.historyPoints.map((e) => e.x).toList();
              final allY = widget.controller.historyPoints.map((e) => e.y).toList();
              final minPossibleX = allX.reduce((a, b) => a < b ? a : b);
              final maxPossibleX = allX.reduce((a, b) => a > b ? a : b);
              final minPossibleY = allY.reduce((a, b) => a < b ? a : b) * 0.9;
              final maxPossibleY = allY.reduce((a, b) => a > b ? a : b) * 1.1;

              // Zoom toward/away from center
              final newXRange = xRange / scaleFactor;
              final newYRange = yRange / scaleFactor;

              widget.controller.minX.value = (xCenter - newXRange / 2).clamp(minPossibleX, maxPossibleX - newXRange);
              widget.controller.maxX.value = (xCenter + newXRange / 2).clamp(minPossibleX + newXRange, maxPossibleX);
              widget.controller.minY.value = (yCenter - newYRange / 2).clamp(minPossibleY, maxPossibleY - newYRange);
              widget.controller.maxY.value = (yCenter + newYRange / 2).clamp(minPossibleY + newYRange, maxPossibleY);
            }
          }
        },
        onPanUpdate: (details) {
          if (_isMultiTouch) {
            return;
          }

          // Single finger pan (both horizontal and vertical)
          final dx = details.delta.dx;
          final dy = details.delta.dy;

          // Pan horizontally (X-axis - time)
          if (dx.abs() > 0.5) {
            final xRange = widget.controller.maxX.value - widget.controller.minX.value;
            final sensitivity = xRange / 200;

            final allX = widget.controller.historyPoints.map((e) => e.x).toList();
            final minPossibleX = allX.reduce((a, b) => a < b ? a : b);
            final maxPossibleX = allX.reduce((a, b) => a > b ? a : b);

            final deltaX = -dx * sensitivity; // Negative for natural scrolling
            final newMinX = (widget.controller.minX.value + deltaX).clamp(minPossibleX, maxPossibleX - xRange);
            final newMaxX = (widget.controller.maxX.value + deltaX).clamp(minPossibleX + xRange, maxPossibleX);

            widget.controller.minX.value = newMinX;
            widget.controller.maxX.value = newMaxX;
          }

          // Pan vertically (Y-axis - values)
          if (dy.abs() > 0.5) {
            final yRange = widget.controller.maxY.value - widget.controller.minY.value;
            final sensitivity = yRange / 200;

            final allY = widget.controller.historyPoints.map((e) => e.y).toList();
            final minPossibleY = allY.reduce((a, b) => a < b ? a : b) * 0.9;
            final maxPossibleY = allY.reduce((a, b) => a > b ? a : b) * 1.1;

            final deltaY = dy * sensitivity;
            final newMinY = (widget.controller.minY.value + deltaY).clamp(minPossibleY, maxPossibleY - yRange);
            final newMaxY = (widget.controller.maxY.value + deltaY).clamp(minPossibleY + yRange, maxPossibleY);

            widget.controller.minY.value = newMinY;
            widget.controller.maxY.value = newMaxY;
          }
        },
        onScaleEnd: (details) {
          // Reset multi-touch flag after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _isMultiTouch = false;
              });
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 10, bottom: 10),
          child: AbsorbPointer(
            absorbing: _isMultiTouch, // Block ALL chart interaction during pinch
            child: LineChart(
              LineChartData(
                clipData: FlClipData.all(), // Only show data within visible bounds
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: null,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < widget.controller.historyDates.length) {
                          // Show every nth label based on visible range
                          final visibleRange = widget.controller.maxX.value - widget.controller.minX.value;
                          final interval = visibleRange > 10 ? (visibleRange / 6).ceil() : 1;

                          if ((index - widget.controller.minX.value.toInt()) % interval == 0 ||
                              index == widget.controller.maxX.value.toInt()) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                widget.controller.historyDates[index],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: null,
                      getTitlesWidget: (val, _) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          val.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
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
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: false, // Disable chart touch so drag works on plot area
                  handleBuiltInTouches: false,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: widget.controller.historyPoints,
                    isCurved: true,
                    color: AppColors.primaryOrange,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primaryOrange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withValues(alpha: 0.3),
                          AppColors.primaryOrange.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minX: widget.controller.minX.value,
                maxX: widget.controller.maxX.value,
                minY: widget.controller.minY.value,
                maxY: widget.controller.maxY.value,
              ),
              duration: const Duration(milliseconds: 150),
              curve: Curves.linear,
            ),
          ),
        ),
      );
            });
  }
}
