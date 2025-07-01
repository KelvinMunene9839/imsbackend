import 'package:flutter/material.dart';

class AdminWelcomePage extends StatelessWidget {
  final String? adminName;
  final int totalAssets;
  final int totalInvestors;
  final double totalContributions;
  final int pendingApprovals;
  final double totalAssetValue;
  final String currencySymbol;

  const AdminWelcomePage({
    super.key,
    this.adminName,
    this.totalAssets = 0,
    this.totalInvestors = 0,
    this.totalContributions = 0.0,
    this.pendingApprovals = 0,
    this.totalAssetValue = 0.0,
    this.currencySymbol = 'FRw',
  });

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
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2;
              double width = constraints.maxWidth;
              if (width > 800) {
                crossAxisCount = 4;
              } else if (width > 600) {
                crossAxisCount = 3;
              }
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 170 / 150,
                children: [
                  _StatCard(
                    icon: Icons.account_balance,
                    label: 'Total Assets',
                    valueWidget: Text(
                      totalAssets.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    color: Colors.blue.shade100,
                  ),
                  _StatCard(
                    icon: null,
                    label: 'Total Asset Value',
                    valueWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencySymbol,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          totalAssetValue.toStringAsFixed(2),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    color: Colors.purple.shade100,
                  ),
                  _StatCard(
                    icon: Icons.people,
                    label: 'Investors',
                    valueWidget: Text(
                      totalInvestors.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    color: Colors.green.shade100,
                  ),
                  _StatCard(
                    icon: null,
                    label: 'Contributions',
                    valueWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencySymbol,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          totalContributions.toStringAsFixed(2),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    color: Colors.orange.shade100,
                  ),
                  _StatCard(
                    icon: Icons.pending_actions,
                    label: 'Pending Approvals',
                    valueWidget: Text(
                      pendingApprovals.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    color: Colors.red.shade100,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Asset'),
                  onPressed: () {}, // TODO: Implement
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Investor'),
                  onPressed: () {}, // TODO: Implement
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.insert_chart),
                  label: const Text('View Reports'),
                  onPressed: () {}, // TODO: Implement
                ),
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
  final IconData? icon;
  final String label;
  final Widget valueWidget;
  final Color color;

  const _StatCard({
    this.icon,
    required this.label,
    required this.valueWidget,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 150),
      child: Container(
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
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 32, color: Colors.black54),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: valueWidget,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
