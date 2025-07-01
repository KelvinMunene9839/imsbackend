import 'package:flutter/material.dart';
import 'overview_tab.dart';
import 'contributions_tab.dart';
import 'interest_tab.dart';
import 'rankings_tab.dart';
import 'asset_ownership_tab.dart';

class InvestorDashboard extends StatefulWidget {
  const InvestorDashboard({super.key});

  @override
  State<InvestorDashboard> createState() => _InvestorDashboardState();
}

class _InvestorDashboardState extends State<InvestorDashboard> {
  int _selectedIndex = 0;
  final List<String> _tabs = [
    'Overview',
    'Contributions',
    'Interest',
    'Rankings',
    'Asset Ownership',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Investor Dashboard'),
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
              decoration: BoxDecoration(color: Color(0xFF18332B)),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          double horizontalPadding = 24.0;
          if (constraints.maxWidth < 400) {
            horizontalPadding = 12.0;
          } else if (constraints.maxWidth < 600) {
            horizontalPadding = 16.0;
          }
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                OverviewTab(),
                ContributionsTab(),
                InterestTab(),
                RankingsTab(),
                InvestorAssetOwnershipTab(),
              ],
            ),
          );
        },
      ),
    );
  }
}
