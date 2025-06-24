import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'contribution_trends_chart.dart';
import 'package:frontend/config.dart';
import '../../widgets/stat_card.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  List<dynamic> reports = [];
  bool isLoading = true;
  List<Map<String, dynamic>> monthlyContributions = [];
  bool isLoadingChart = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
    fetchMonthlyContributions();
  }

  Future<void> fetchReports() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.get(
      Uri.parse('$backendBaseUrl/api/admin/report/assets'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      try {
        setState(() {
          reports = jsonDecode(response.body);
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print('Error parsing reports JSON: $e');
      }
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to fetch reports: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> fetchMonthlyContributions() async {
    setState(() {
      isLoadingChart = true;
    });
    final response = await http.get(
      Uri.parse('$backendBaseUrl/api/admin/report/contributions/monthly'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as List;
        // Group by month-year and sum totals
        final Map<String, double> monthTotals = {};
        for (final row in data) {
          final month = row['month'].toString().padLeft(2, '0');
          final year = row['year'].toString();
          final key = '$year-$month';
          monthTotals[key] =
              (monthTotals[key] ?? 0) + (row['total'] as num).toDouble();
        }
        final sortedKeys = monthTotals.keys.toList()..sort();
        setState(() {
          monthlyContributions = [
            for (final k in sortedKeys) {'month': k, 'total': monthTotals[k]},
          ];
          isLoadingChart = false;
        });
      } catch (e) {
        setState(() {
          isLoadingChart = false;
        });
        print('Error parsing monthly contributions JSON: $e');
      }
    } else {
      setState(() {
        isLoadingChart = false;
      });
      print(
        'Failed to fetch monthly contributions: ${response.statusCode} ${response.body}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Reports',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18332B),
                  ),
                ),
              ),
              Row(
                children: [
                  StatCard(
                    title: 'Total Reports',
                    value: reports.length.toString(),
                    icon: Icons.insert_chart,
                    color: const Color(0xFF18332B),
                  ),
                  const SizedBox(width: 16),
                  StatCard(
                    title: 'Monthly Trends',
                    value: monthlyContributions.isNotEmpty
                        ? monthlyContributions.last['total'].toString()
                        : '-',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Contribution Trends',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              isLoadingChart
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ContributionTrendsChart(
                        data: monthlyContributions,
                      ),
                    ),
              const Divider(),
              const Text(
                'Asset Ownership Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reports.length,
                      itemBuilder: (context, idx) {
                        final asset = reports[idx];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text('Asset: ${asset['name']}'),
                            subtitle: Text('Value: ${asset['value']}'),
                            isThreeLine: true,
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Ownership:'),
                                ...((asset['ownerships'] as List)
                                    .map(
                                      (o) => Text(
                                        '${o['name']}: ${o['percentage']}%',
                                      ),
                                    )
                                    .toList()),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16)
            ],
          );
  }
}
