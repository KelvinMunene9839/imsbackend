import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ContributionTrendsChart extends StatelessWidget {
  final List<Map<String, dynamic>>
  data; // [{month: '2025-01', total: 1000}, ...]
  const ContributionTrendsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data for chart'));
    }
    final spots = data
        .asMap()
        .entries
        .map(
          (e) => FlSpot(e.key.toDouble(), (e.value['total'] as num).toDouble()),
        )
        .toList();
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(data[idx]['month'] ?? '');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
