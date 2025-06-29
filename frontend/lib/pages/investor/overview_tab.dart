import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  File? _profileImage;
  String? _profileImageUrl;

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
          // Set profile image URL if available
          _profileImageUrl =
              data['image'] != null && data['image'].toString().isNotEmpty
              ? (data['image'].toString().startsWith('http')
                    ? data['image']
                    : '$backendBaseUrl/${data['image']}')
              : null;
          _profileImage = null; // Reset local image after fetch
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

  Future<void> _pickProfileImage(StateSetter setModalState) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setModalState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _pickProfileImage(setModalState),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (_profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                      as ImageProvider
                                : null),
                      child: _profileImage == null && _profileImageUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await saveProfileWithImage(setModalState);
                if (error == null) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveProfileWithImage(StateSetter setModalState) async {
    setModalState(() {
      isLoading = true;
      error = null;
    });
    try {
      final investorId = await getInvestorId();
      if (investorId == null) {
        setModalState(() {
          error = 'No investor ID found. Please log in again.';
          isLoading = false;
        });
        return;
      }
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$backendBaseUrl/api/investor/me?id=$investorId'),
      );
      request.fields['name'] = nameController.text;
      request.fields['email'] = emailController.text;
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _profileImage!.path),
        );
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        setModalState(() {
          isEditing = false;
          error = null;
        });
        await fetchInvestor();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
        }
      } else {
        String backendError = 'Failed to update profile.';
        try {
          final resp = jsonDecode(response.body);
          if (resp is Map && resp['error'] != null) {
            backendError = resp['error'].toString();
          }
        } catch (_) {}
        setModalState(() {
          error = backendError;
        });
      }
    } catch (e) {
      setModalState(() {
        error = 'Error: $e';
      });
    } finally {
      setModalState(() {
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
          width: MediaQuery.of(context).size.width < 500
              ? double.infinity
              : 220,
          child: StatCard(
            title: 'Total Contributions',
            value: '\$${investorData!['total_contributions'] ?? '0'}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width < 500
              ? double.infinity
              : 220,
          child: StatCard(
            title: 'Percentage Share',
            value: '${investorData!['percentage_share'] ?? '0'}%',
            icon: Icons.pie_chart,
            color: Colors.blue,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width < 500
              ? double.infinity
              : 220,
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
            onViewProfile: _showProfileDialog,
            imageUrl: _profileImageUrl,
          ),
          const SizedBox(height: 16),
          buildStatCards(),
          const SizedBox(height: 16),
          ImsCard(child: buildRecentTransactions()),
        ],
      ),
    );
  }
}
