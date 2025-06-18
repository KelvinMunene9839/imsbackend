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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showForm)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
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
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    if (errorMsg != null)
                      Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            showForm = true;
                          }),
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
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => setState(() {
                  showForm = true;
                }),
                child: const Text('Add Investor'),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Investors',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF18332B),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: investors.length,
                        itemBuilder: (context, index) {
                          final investor = investors[index];
                          return InvestorListItem(
                            name: investor['name'] ?? '',
                            status: investor['status'] ?? '',
                            amount: '\$${investor['amount'] ?? '0'}',
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
