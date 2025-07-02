import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
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
  Uint8List? _profileImageBytes;
  String? _profileImageName;
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

  String? buildFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('http')) return imageUrl;
    final cleanPath = imageUrl.replaceFirst(RegExp(r'^/+'), '');
    return '$backendBaseUrl/$cleanPath';
  }

  Future<void> fetchInvestor() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    final investorId = await getInvestorId();
    if (investorId == null) {
      setState(() {
        error = 'No investor ID found. Please log in again.';
        isLoading = false;
      });
      return;
    }
    try {
      final res = await apiClient.get('/me?id=$investorId');
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(res.body));
        final builtUrl = buildFullImageUrl(data['imageUrl']);
        setState(() {
          investorData = data;
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          _profileImageUrl = builtUrl;
          _profileImage = null;
          _profileImageBytes = null;
          _profileImageName = null;
          isLoading = false;
        });
        // Debug print after state update
        print(
          'fetchInvestor: backend imageUrl = \'${data['imageUrl']}\', built _profileImageUrl = $builtUrl',
        );
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
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      if (kIsWeb) {
        setModalState(() {
          _profileImageBytes = result.files.single.bytes;
          _profileImage = null;
          _profileImageName = result.files.single.name;
        });
      } else {
        setModalState(() {
          _profileImage = File(result.files.single.path!);
          _profileImageBytes = null;
          _profileImageName = result.files.single.name;
        });
      }
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
                      backgroundImage: _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!)
                          : _profileImage != null
                          ? FileImage(_profileImage!)
                          : (_profileImageUrl != null &&
                                    _profileImageUrl!.isNotEmpty
                                ? NetworkImage(_profileImageUrl!)
                                : null),
                      child:
                          (_profileImageBytes == null &&
                              _profileImage == null &&
                              (_profileImageUrl == null ||
                                  _profileImageUrl!.isEmpty))
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
      } else if (_profileImageBytes != null && _profileImageName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _profileImageBytes!,
            filename: _profileImageName,
          ),
        );
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final responseData = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );
        final newImageUrl = buildFullImageUrl(responseData['imageUrl']);
        setModalState(() {
          isEditing = false;
          error = null;
          _profileImageUrl = newImageUrl;
          _profileImage = null;
          _profileImageBytes = null;
          _profileImageName = null;
        });
        setState(() {
          investorData = responseData;
          _profileImageUrl = newImageUrl;
          nameController.text = responseData['name'] ?? '';
          emailController.text = responseData['email'] ?? '';
        });
        // Debug print after state update
        print(
          'saveProfileWithImage: backend imageUrl = \'${responseData['imageUrl']}\', built _profileImageUrl = $newImageUrl',
        );
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
        }),
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
