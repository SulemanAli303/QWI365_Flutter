import 'package:flutter/material.dart';

class DropletIndicator extends StatelessWidget {
  final String label;
  final double value;
  final double refillPoint;
  final Color color;

  const DropletIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.refillPoint,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Replicating the custom horizontal progress bar feel
    double progress = value / 100.0; // Assuming 0-100 range
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.water_drop, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${value.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
                const SizedBox(height: 2),
                Text(
                  'Refill Point: ${refillPoint.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
