import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../error_messages.dart';

class InvestorAssetOwnershipTab extends StatefulWidget {
  const InvestorAssetOwnershipTab({super.key});

  @override
  State<InvestorAssetOwnershipTab> createState() =>
      _InvestorAssetOwnershipTabState();
}

class _InvestorAssetOwnershipTabState extends State<InvestorAssetOwnershipTab> {
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
      final prefs = await SharedPreferences.getInstance();
      final investorId = prefs.getString('investorId');
      if (investorId == null) {
        setState(() {
          error = ErrorMessages.investorIdNotFound;
          isLoading = false;
        });
        return;
      }
      final url = '$backendBaseUrl/api/admin/investor/assets?investorId=$investorId';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          assets = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = ErrorMessages.failedToFetchData;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = '${ErrorMessages.serverError} Exception: $e';
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
      return Center(
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (assets.isEmpty) {
      return const Center(child: Text('No asset ownership data available.'));
    }

    return RefreshIndicator(
      onRefresh: fetchAssets,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: assets.length,
        itemBuilder: (context, idx) {
          final asset = assets[idx];
          final ownerships = asset['ownerships'] as List<dynamic>? ?? [];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            child: ExpansionTile(
              title: Text(
                asset['name'] ?? 'Unnamed Asset',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text("Value: ₦${asset['value'] ?? 'N/A'}"),
              children: [
                if (ownerships.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('No ownership data for this asset.'),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: ownerships.map((o) {
                        final percentRaw = o['percentage'] ?? 0;
                        final percent = (percentRaw is String)
                            ? double.tryParse(percentRaw) ?? 0.0
                            : (percentRaw as num).toDouble();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  o['name'] ?? 'Unknown',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LinearProgressIndicator(
                                      value: percent / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[200],
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${percent.toStringAsFixed(2)}%  (₦${o['amount'] ?? 'N/A'})",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
