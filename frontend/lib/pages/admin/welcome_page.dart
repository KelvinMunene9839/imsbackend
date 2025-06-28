import 'package:flutter/material.dart';

class AdminWelcomePage extends StatelessWidget {
  final String? adminName;
  final int totalAssets;
  final int totalInvestors;
  final double totalContributions;
  final int pendingApprovals;

  const AdminWelcomePage({
    Key? key,
    this.adminName,
    this.totalAssets = 0,
    this.totalInvestors = 0,
    this.totalContributions = 0.0,
    this.pendingApprovals = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back${adminName != null ? ", $adminName" : ""}!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Here is a quick overview of your system today.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                icon: Icons.account_balance,
                label: 'Total Assets',
                value: totalAssets.toString(),
                color: Colors.blue.shade100,
              ),
              _StatCard(
                icon: Icons.people,
                label: 'Investors',
                value: totalInvestors.toString(),
                color: Colors.green.shade100,
              ),
              _StatCard(
                icon: Icons.attach_money,
                label: 'Contributions',
                value: '₦${totalContributions.toStringAsFixed(2)}',
                color: Colors.orange.shade100,
              ),
              _StatCard(
                icon: Icons.pending_actions,
                label: 'Pending Approvals',
                value: pendingApprovals.toString(),
                color: Colors.red.shade100,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Asset'),
                onPressed: () {}, // TODO: Implement
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Add Investor'),
                onPressed: () {}, // TODO: Implement
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.insert_chart),
                label: const Text('View Reports'),
                onPressed: () {}, // TODO: Implement
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('No recent activity.'),
              subtitle: const Text('All systems normal.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Colors.black54),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
