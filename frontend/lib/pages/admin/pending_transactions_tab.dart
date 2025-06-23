import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';
import '../../widgets/stat_card.dart';

class PendingTransactionsTab extends StatefulWidget {
  const PendingTransactionsTab({super.key});

  @override
  State<PendingTransactionsTab> createState() => _PendingTransactionsTabState();
}

class _PendingTransactionsTabState extends State<PendingTransactionsTab> {
  List<dynamic> pendingTransactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingTransactions();
  }

  Future<void> fetchPendingTransactions() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.get(
      Uri.parse('$backendBaseUrl/api/admin/transactions/pending'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      try {
        setState(() {
          pendingTransactions = jsonDecode(response.body);
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print('Error parsing pending transactions JSON: $e');
      }
    } else {
      setState(() {
        isLoading = false;
      });
      print(
        'Failed to fetch pending transactions: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> approveOrReject(int id, String status) async {
    final response = await http.patch(
      Uri.parse('$backendBaseUrl/api/admin/transaction/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      fetchPendingTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Pending Transactions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18332B),
                  ),
                ),
              ),
              StatCard(
                title: 'Pending Transactions',
                value: pendingTransactions.length.toString(),
                icon: Icons.pending_actions,
                color: const Color(0xFF18332B),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: pendingTransactions.length,
                  itemBuilder: (context, idx) {
                    final tx = pendingTransactions[idx];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text("Investor: ${tx['investor_name']}"),
                        subtitle: Text(
                          "Amount: ${tx['amount']} | Date: ${tx['date']}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  approveOrReject(tx['id'], 'approved'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  approveOrReject(tx['id'], 'rejected'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}
