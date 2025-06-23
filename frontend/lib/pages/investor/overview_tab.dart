import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../api_client.dart';
import '../../config.dart';
import '../../widgets/ims_card.dart';

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

  Future<void> fetchInvestor() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      // TODO: Replace with actual investor id from auth/session
      const investorId = '1';
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
      const investorId = '1';
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${investorData?['name'] ?? ''}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Email: ${investorData?['email'] ?? ''}'),
                const SizedBox(height: 16),
                if (!isEditing)
                  ElevatedButton(
                    onPressed: () => setState(() => isEditing = true),
                    child: const Text('Edit Profile'),
                  ),
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
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
