import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_theme.dart';
import 'assets_tab.dart';
import 'interest_rates_tab.dart';
import 'pending_transactions_tab.dart';
import 'reports_tab.dart';
import 'penalties_tab.dart';
import 'investors_tab.dart';
import 'asset_ownership_tab.dart';
import 'welcome_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final List<String> _tabs = [
    'Welcome',
    'Pending Transactions',
    'Assets',
    'Investors',
    'Reports',
    'Penalties',
    'Interest Rates',
    'Asset Ownership',
  ];

  int totalAssets = 0;
  int totalInvestors = 0;
  double totalContributions = 0.0;
  int pendingApprovals = 0;
  List<dynamic> assetOwnerships = [];
  double totalAssetValue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final assetsResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/admin/report/assets'),
      );
      final investorsResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/admin/investors'),
      );
      final contributionsResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/admin/report/contributions/yearly'),
      );
      final pendingResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/admin/pending-approvals'),
      );
      final totalAssetValueResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/admin/total-asset-value'),
      );

      if (assetsResponse.statusCode == 200) {
        final assetsData = jsonDecode(assetsResponse.body);
        setState(() {
          totalAssets = (assetsData as List).length;
          assetOwnerships = assetsData;
        });
      }

      if (investorsResponse.statusCode == 200) {
        final investorsData = jsonDecode(investorsResponse.body);
        setState(() {
          totalInvestors = (investorsData as List).length;
        });
      }

      if (contributionsResponse.statusCode == 200) {
        final contributionsData = jsonDecode(contributionsResponse.body);
        double total = 0.0;
        for (var item in contributionsData) {
          total += (item['total'] is String)
              ? double.tryParse(item['total']) ?? 0.0
              : (item['total'] ?? 0.0);
        }
        setState(() {
          totalContributions = total;
        });
      }

      if (pendingResponse.statusCode == 200) {
        final pendingData = jsonDecode(pendingResponse.body);
        setState(() {
          pendingApprovals = (pendingData as List).length;
        });
      }

      if (totalAssetValueResponse.statusCode == 200) {
        final data = jsonDecode(totalAssetValueResponse.body);
        setState(() {
          totalAssetValue = (data['total'] is num)
              ? data['total'].toDouble()
              : double.tryParse(data['total'].toString()) ?? 0.0;
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  void _onTabChanged(int index) async {
    setState(() => _selectedIndex = index);
    // If Welcome tab is selected, refresh all dashboard data
    if (_tabs[index] == 'Welcome') {
      await _fetchDashboardData();
    }
    // If Asset Ownership tab is selected, refresh asset ownerships
    if (_tabs[index] == 'Asset Ownership') {
      try {
        final assetsResponse = await http.get(
          Uri.parse('$backendBaseUrl/api/admin/report/assets'),
        );
        if (assetsResponse.statusCode == 200) {
          final assetsData = jsonDecode(assetsResponse.body);
          setState(() {
            assetOwnerships = assetsData;
          });
        }
      } catch (e) {
        print('Error refreshing asset ownership data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primary),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ..._tabs.asMap().entries.map(
              (entry) => ListTile(
                title: Text(entry.value),
                selected: _selectedIndex == entry.key,
                onTap: () => _onTabChanged(entry.key),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            AdminWelcomePage(
              adminName:
                  'Admin', // TODO: Replace with actual admin name if available
              totalAssets: totalAssets,
              totalInvestors: totalInvestors,
              totalContributions: totalContributions,
              pendingApprovals: pendingApprovals,
              totalAssetValue: totalAssetValue,
            ),
            PendingTransactionsTab(),
            AssetsTab(),
            InvestorsTab(),
            ReportsTab(),
            PenaltiesTab(),
            InterestRatesTab(),
            AssetOwnershipTab(),
          ],
        ),
      ),
    );
  }
}
