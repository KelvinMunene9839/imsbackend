import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class AssetOwnershipTab extends StatefulWidget {
  const AssetOwnershipTab({super.key});

  @override
  State<AssetOwnershipTab> createState() => _AssetOwnershipTabState();
}

class _AssetOwnershipTabState extends State<AssetOwnershipTab> {
  List<dynamic> assets = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAssets();
  }

  Future<void> fetchAssets() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/api/admin/report/assets'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          assets = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to fetch asset ownership data.';
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!));
    }
    if (assets.isEmpty) {
      return const Center(child: Text('No asset ownership data available.'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: assets.length,
      itemBuilder: (context, idx) {
        final asset = assets[idx];
        final ownerships = (asset['ownerships'] as List?) ?? [];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text('Asset: ${asset['name'] ?? '-'}'),
            subtitle: Text('Value: ₦${asset['value'] ?? '-'}'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ownerships.isEmpty
                    ? const Text('No ownership data for this asset.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ownership Breakdown:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...ownerships.map((o) {
                            final name = o['name'] ?? '-';
                            final percentage = o['percentage'] ?? 0;
                            final amount = o['amount'];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                ),
                              ),
                              title: Text(name),
                              subtitle: amount != null
                                  ? Text('₦$amount')
                                  : null,
                              trailing: SizedBox(
                                width: 120,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('${percentage.toStringAsFixed(2)}%'),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: (percentage is num)
                                            ? (percentage / 100).clamp(0.0, 1.0)
                                            : 0.0,
                                        minHeight: 6,
                                        backgroundColor: Colors.grey[200],
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
