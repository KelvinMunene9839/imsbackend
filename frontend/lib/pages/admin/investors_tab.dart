import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:frontend/config.dart';
import 'package:frontend/api_client.dart';
import '../../widgets/investor_list_item.dart';

class InvestorsTab extends StatefulWidget {
  const InvestorsTab({super.key});

  @override
  State<InvestorsTab> createState() => _InvestorsTabState();
}

class _InvestorsTabState extends State<InvestorsTab> {
  List<dynamic> investors = [];
  bool isLoading = true;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool showForm = false;
  String? errorMsg;

  late ApiClient apiClient;

  @override
  void initState() {
    super.initState();
    apiClient = ApiClient(baseUrl: backendBaseUrl);
    fetchInvestors();
  }

  Future<void> fetchInvestors() async {
    print('Using backendBaseUrl in investors_tab: $backendBaseUrl');
    setState(() {
      isLoading = true;
    });
    final response = await apiClient.get('/api/admin/investor');
    print('fetchInvestors response status: ${response.statusCode}');
    print('fetchInvestors response body: ${response.body}');
    if (response.statusCode == 200) {
      setState(() {
        investors = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addInvestor() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        errorMsg = 'All fields are required.';
      });
      return;
    }
    setState(() {
      errorMsg = null;
    });
    final response = await apiClient.post('/api/admin/investor', {
      'name': name,
      'email': email,
      'password': password,
    });
    if (response.statusCode == 201) {
      setState(() {
        showForm = false;
      });
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      fetchInvestors();
    } else {
      String backendMessage = 'Failed to add investor.';
      try {
        final responseBody = jsonDecode(response.body);
        if (responseBody['message'] != null) {
          backendMessage = responseBody['message'];
        }
      } catch (_) {}
      setState(() {
        errorMsg = backendMessage;
      });
    }
  }

  Future<void> editInvestor(Map<String, dynamic> investor) async {
    nameController.text = investor['name'] ?? '';
    emailController.text = investor['email'] ?? '';
    passwordController.clear();
    setState(() {
      showForm = true;
      errorMsg = null;
    });
    // Wait for user to submit the form, then update
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Investor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password (leave blank to keep current)',
              ),
              obscureText: true,
            ),
            if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  errorMsg!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final password = passwordController.text.trim();
              if (name.isEmpty || email.isEmpty) {
                setState(() {
                  errorMsg = 'Name and email are required.';
                });
                return;
              }
              final response = await apiClient
                  .patch('/api/admin/investor/${investor['id']}', {
                    'name': name,
                    'email': email,
                    if (password.isNotEmpty) 'password': password,
                  });
              if (response.statusCode == 200) {
                Navigator.pop(context);
                fetchInvestors();
              } else {
                setState(() {
                  errorMsg = 'Failed to update investor.';
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteInvestor(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investor'),
        content: const Text('Are you sure you want to delete this investor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final response = await apiClient.delete('/api/admin/investor/$id');
      if (response.statusCode == 200) {
        fetchInvestors();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Investor deleted.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete investor.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (showForm)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                        ),
                        if (errorMsg != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              errorMsg!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => showForm = false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: addInvestor,
                              child: const Text('Add Investor'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18332B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => setState(() => showForm = true),
                    child: const Text('Add Investor'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Investors',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18332B),
                ),
              ),
              const SizedBox(height: 12),
              ...investors.map(
                (investor) => Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF18332B),
                      child: Text(
                        (investor['name'] ?? '').isNotEmpty
                            ? investor['name'][0].toUpperCase()
                            : '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      investor['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(investor['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (investor['status'] == 'active')
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            investor['status'] ?? '',
                            style: TextStyle(
                              color: (investor['status'] == 'active')
                                  ? Colors.green[800]
                                  : Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            color: const Color(0xFF18332B),
                          ),
                          tooltip: 'View',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Investor Details'),
                                content: Text(
                                  'Name: ${investor['name'] ?? ''}\nEmail: ${investor['email'] ?? ''}\nStatus: ${investor['status'] ?? ''}',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color:const Color(0xFF18332B)),
                          tooltip: 'Edit',
                          onPressed: () => editInvestor(investor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => deleteInvestor(investor['id']),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
