import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_client.dart';
import '../../config.dart';
import '../../widgets/ims_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/profile_card.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final ApiClient apiClient = ApiClient(
    baseUrl: '$backendBaseUrl/api/investor',
  );
  Map<String, dynamic>? investorData;
  bool isLoading = true;
  bool isEditing = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? error;

  @override
  void initState() {
    super.initState();
    fetchInvestor();
  }

  Future<String?> getInvestorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('investorId');
  }

  Future<void> fetchInvestor() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final investorId = await getInvestorId();
      if (investorId == null) {
        setState(() {
          error = 'No investor ID found. Please log in again.';
          isLoading = false;
        });
        return;
      }
      final res = await apiClient.get('/me?id=$investorId');
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(res.body));
        setState(() {
          investorData = data;
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load profile.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> saveProfile() async {
    setState(() {
      isLoading = true;
    });
    try {
      final investorId = await getInvestorId();
      if (investorId == null) {
        setState(() {
          error = 'No investor ID found. Please log in again.';
          isLoading = false;
        });
        return;
      }
      final res = await apiClient.patch('/me?id=$investorId', {
        'name': nameController.text,
        'email': emailController.text,
      });
      if (res.statusCode == 200) {
        setState(() {
          isEditing = false;
        });
        await fetchInvestor();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      } else {
        setState(() {
          error = 'Failed to update profile.';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildStatCards() {
    if (investorData == null) return Container();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width < 500 ? double.infinity : 220,
          child: StatCard(
            title: 'Total Contributions',
            value: '\$${investorData!['total_contributions'] ?? '0'}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width < 500 ? double.infinity : 220,
          child: StatCard(
            title: 'Percentage Share',
            value: '${investorData!['percentage_share'] ?? '0'}%',
            icon: Icons.pie_chart,
            color: Colors.blue,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width < 500 ? double.infinity : 220,
          child: StatCard(
            title: 'Transactions',
            value:
                '${(investorData!['transactions'] as List<dynamic>?)?.length ?? 0}',
            icon: Icons.list_alt,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget buildRecentTransactions() {
    if (investorData == null) return Container();
    final transactions = (investorData!['transactions'] as List<dynamic>?);
    if (transactions == null || transactions.isEmpty) {
      return const Text('No recent transactions.');
    }
    final recent = transactions.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...recent.map((tx) {
          final amount = tx['amount'] ?? 0;
          final date = tx['date'] ?? '';
          final status = tx['status'] ?? '';
          return ListTile(
            title: Text('\$${amount.toString()}'),
            subtitle: Text(date),
            trailing: Text(status),
          );
        }).toList(),
        TextButton(
          onPressed: () {
            // Navigate to Contributions tab or page
            // TODO: Implement navigation
          },
          child: const Text('View All'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileCard(
            name: investorData?['name'] ?? '',
            amount: investorData?['status'] ?? 'Unknown',
            onViewProfile: () => setState(() => isEditing = true),
          ),
          const SizedBox(height: 16),
          if (isEditing)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: saveProfile,
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => isEditing = false),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          buildStatCards(),
          const SizedBox(height: 16),
          ImsCard(child: buildRecentTransactions()),
        ],
      ),
    );
  }
}
