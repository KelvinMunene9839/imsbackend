import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';
import 'package:image_picker/image_picker.dart';

class InvestorDashboard extends StatefulWidget {
  const InvestorDashboard({super.key});

  @override
  State<InvestorDashboard> createState() => _InvestorDashboardState();
}

class _InvestorDashboardState extends State<InvestorDashboard> {
  Map<String, dynamic>? investorData;
  bool isLoading = true;
  final TextEditingController amountController = TextEditingController();
  String? txError;
  bool txLoading = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.get(
      Uri.parse('backendBaseUrl/api/investor/me?id=1'),
    );
    if (response.statusCode == 200) {
      setState(() {
        investorData = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile(String name, String email, File? image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$backendBaseUrl/api/investor/me/update'),
    );
    request.fields['name'] = name;
    request.fields['email'] = email;
    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      fetchDashboard();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile.')));
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: investorData?['name'] ?? '',
    );
    final emailController = TextEditingController(
      text: investorData?['email'] ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    setState(() {
                      _profileImage = File(picked.path);
                    });
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (investorData?['imageUrl'] != null
                                    ? NetworkImage(investorData!['imageUrl'])
                                    : null)
                                as ImageProvider?,
                      child:
                          _profileImage == null &&
                              investorData?['imageUrl'] == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
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
                await _updateProfile(
                  nameController.text,
                  emailController.text,
                  _profileImage,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investor Dashboard')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investor Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text('Welcome - Ently'),
                  const SizedBox(height: 16),
                  Text('Record Contribution'),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: investorData?['imageUrl'] != null
                                ? NetworkImage(investorData!['imageUrl'])
                                : null,
                            child: investorData?['imageUrl'] == null
                                ? const Icon(Icons.person, size: 36)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility, size: 20),
                            onPressed: _showEditProfileDialog,
                            tooltip: 'View Profile',
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Text(
                        investorData?['name'] ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
