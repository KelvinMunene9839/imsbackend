import 'package:flutter/material.dart';
import '../widgets/app_theme.dart';
import 'admin/assets_tab.dart';
import 'admin/interest_rates_tab.dart';
import 'admin/pending_transactions_tab.dart';
import 'admin/reports_tab.dart';
import 'admin/penalties_tab.dart';
import 'admin/investors_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final List<String> _tabs = [
    'Pending Transactions',
    'Assets',
    'Investors',
    'Reports',
    'Penalties',
    'Interest Rates',
  ];

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
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ..._tabs.asMap().entries.map(
                  (entry) => ListTile(
                    title: Text(entry.value),
                    selected: _selectedIndex == entry.key,
                    onTap: () {
                      setState(() => _selectedIndex = entry.key);
                      Navigator.pop(context);
                    },
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
            PendingTransactionsTab(),
            AssetsTab(),
            InvestorsTab(),
            ReportsTab(),
            PenaltiesTab(),
            InterestRatesTab(),
          ],
        ),
      ),
    );
  }
}
