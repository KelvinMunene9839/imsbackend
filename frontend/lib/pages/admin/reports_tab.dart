import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';
import '../../widgets/stat_card.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  List<dynamic> allInvestors = [];
  List<dynamic> contributions = [];
  bool isLoading = true;
  String? selectedMonth;
  List<String> availableMonths = [];

  @override
  void initState() {
    super.initState();
    fetchInvestorsAndContributions();
  }

  Future<void> fetchInvestorsAndContributions() async {
    setState(() {
      isLoading = true;
    });
    // Fetch all investors
    final investorsRes = await http.get(
      Uri.parse('$backendBaseUrl/api/admin/investor'),
      headers: {'Content-Type': 'application/json'},
    );
    // Fetch all monthly contributions
    final contribRes = await http.get(
      Uri.parse('$backendBaseUrl/api/admin/report/contributions/monthly'),
      headers: {'Content-Type': 'application/json'},
    );
    if (investorsRes.statusCode == 200 && contribRes.statusCode == 200) {
      final investors = jsonDecode(investorsRes.body) as List;
      final contribs = jsonDecode(contribRes.body) as List;
      // Build available months (format: YYYY-MM)
      final months = contribs
          .map((c) => '${c['year']}-${c['month'].toString().padLeft(2, '0')}')
          .toSet()
          .toList();
      months.sort();
      setState(() {
        allInvestors = investors;
        contributions = contribs;
        availableMonths = months;
        selectedMonth = months.isNotEmpty ? months.last : null;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<dynamic> getContributionsForMonth(String? month) {
    if (month == null) return [];
    return contributions
        .where(
          (c) =>
              '${c['year']}-${c['month'].toString().padLeft(2, '0')}' == month,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final monthContribs = getContributionsForMonth(selectedMonth);
    final totalContributed = monthContribs.fold<double>(
      0.0,
      (sum, c) =>
          sum +
          (c['total'] is num
              ? c['total']
              : double.tryParse(c['total'].toString()) ?? 0.0),
    );
    const currencySymbol = 'FRw';
    final contributorIds = monthContribs.map((c) => c['investor_id']).toSet();
    final numContributors = contributorIds.length;
    final numNonContributors = allInvestors
        .where((inv) => !contributorIds.contains(inv['id']))
        .length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
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
              const Text('Select Month: '),
              DropdownButton<String>(
                value: selectedMonth,
                items: availableMonths
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => selectedMonth = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              StatCard(
                title: 'Total Contributed',
                value: '$currencySymbol ${totalContributed.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              StatCard(
                title: 'Contributors',
                value: numContributors.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
              StatCard(
                title: 'Non-Contributors',
                value: numNonContributors.toString(),
                icon: Icons.person_off,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Investor Contributions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ...allInvestors.map((inv) {
            final contrib = monthContribs.firstWhere(
              (c) => c['investor_id'] == inv['id'],
              orElse: () => null,
            );
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(inv['name'] ?? ''),
                subtitle: Text(inv['email'] ?? ''),
                trailing: Text(
                  contrib != null
                      ? '$currencySymbol ${(contrib['total'] is num ? contrib['total'] : double.tryParse(contrib['total'].toString()) ?? 0.0).toStringAsFixed(2)}'
                      : '$currencySymbol 0.00',
                  style: TextStyle(
                    color: contrib != null
                        ? Colors.green[800]
                        : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
