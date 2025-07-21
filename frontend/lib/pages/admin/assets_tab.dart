import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';

class AssetsTab extends StatefulWidget {
  const AssetsTab({super.key});

  @override
  State<AssetsTab> createState() => _AssetsTabState();
}

class _AssetsTabState extends State<AssetsTab> {
  List<dynamic> assets = [];
  bool isLoading = true;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  bool showForm = false;
  String? errorMsg;

  // For investor contributions
  List<dynamic> investors = [];
  List<TextEditingController> amountControllers = [];
  bool isLoadingInvestors = false;

  Map<int, double> investorsTotalContributions = {};

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.get(
      Uri.parse('$backendBaseUrl/api/admin/assets'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      setState(() {
        assets = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchInvestors() async {
    setState(() {
      isLoadingInvestors = true;
    });
    final response = await http.get(
      Uri.parse('$backendBaseUrl/api/admin/investor'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      investors = jsonDecode(response.body);
      amountControllers = List.generate(
        investors.length,
        (_) => TextEditingController(),
      );
    }
    setState(() {
      isLoadingInvestors = false;
    });
  }

  Future<void> fetchInvestorsTotalContributions() async {
    final response = await http.get(
      Uri.parse('$backendBaseUrl/api/admin/investor/total_contributions'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      investorsTotalContributions = {
        for (var item in data) item['investorId'] as int: (item['totalContributions'] as num).toDouble()
      };
    }
  }

  void showAddAssetForm() async {
    await fetchInvestors();
    await fetchInvestorsTotalContributions();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Asset'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Asset Name',
                      ),
                    ),
                    TextField(
                      controller: valueController,
                      decoration: const InputDecoration(
                        labelText: 'Asset Value',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    if (investors.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Investor Contributions:'),
                          ...List.generate(investors.length, (i) {
                            final amount =
                                double.tryParse(amountControllers[i].text) ??
                                0.0;
                            final percent = totalContribution > 0
                                ? (amount / totalContribution) * 100
                                : 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(investors[i]['name'])),
                                  SizedBox(
                                    width: 90,
                                    child: TextField(
                                      controller: amountControllers[i],
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Amount',
                                      ),
                                      onChanged: (_) {
                                        setState(() {});
                                        setStateDialog(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('${percent.toStringAsFixed(2)}%'),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Text(
                            'Total: FRw ${totalContribution.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    if (errorMsg != null)
                      Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
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
                    await addAsset();
                    if (errorMsg == null) {
                      Navigator.pop(context);
                    } else {
                      setStateDialog(() {});
                    }
                  },
                  child: const Text('Add Asset'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double get totalContribution => amountControllers.fold(
    0.0,
    (sum, c) => sum + (double.tryParse(c.text) ?? 0.0),
  );

  @override
  void dispose() {
    for (final c in amountControllers) {
      c.dispose();
    }
    nameController.dispose();
    valueController.dispose();
    super.dispose();
  }

  Future<void> addAsset() async {
    final name = nameController.text.trim();
    final value = double.tryParse(valueController.text.trim()) ?? 0;
    if (name.isEmpty || value <= 0) {
      setState(() {
        errorMsg = 'Enter valid name and value.';
      });
      return;
    }
    // Collect contributions
    final List<Map<String, dynamic>> contributions = [];
    for (int i = 0; i < investors.length; i++) {
      final amount = double.tryParse(amountControllers[i].text) ?? 0.0;
      if (amount > 0) {
        contributions.add({'investorId': investors[i]['id'], 'amount': amount});
      }
    }
    if (contributions.isEmpty) {
      setState(() {
        errorMsg = 'Enter at least one investor contribution.';
      });
      return;
    }
    // Validation: investor contribution cannot exceed available contributions
    for (final contrib in contributions) {
      final investorId = contrib['investorId'];
      final newAmount = contrib['amount'] as double;
      final totalContrib = investorsTotalContributions[investorId] ?? 0.0;
      // Calculate total contributions for this investor on other assets
      double totalOtherContrib = 0.0;
      for (final asset in assets) {
        if (asset['ownerships'] != null) {
          for (final ownership in asset['ownerships']) {
            if (ownership['investorId'] == investorId) {
              totalOtherContrib += (ownership['amount'] ?? 0);
            }
          }
        }
      }
      final availableAmount = totalContrib - totalOtherContrib;
      if (newAmount > availableAmount) {
        setState(() {
          errorMsg = 'Investor contribution cannot exceed available contributions.';
        });
        return;
      }
    }
    // Validation: total contributions cannot exceed asset value
    final totalContrib = contributions.fold<double>(0.0, (sum, c) => sum + (c['amount'] as double));
    if (totalContrib > value) {
      setState(() {
        errorMsg = 'Total investor contributions cannot exceed asset value.';
      });
      return;
    }
    setState(() {
      errorMsg = null;
    });
    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/admin/asset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'value': value,
        'contributions': contributions,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      setState(() {
        showForm = false;
      });
      nameController.clear();
      valueController.clear();
      for (final c in amountControllers) {
        c.clear();
      }
      _fetchAssets();
    } else {
      setState(() {
        errorMsg = 'Failed to add asset.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double horizontalPadding = 24.0;
        if (constraints.maxWidth < 400) {
          horizontalPadding = 12.0;
        } else if (constraints.maxWidth < 600) {
          horizontalPadding = 16.0;
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: assets.length,
                        itemBuilder: (context, idx) {
                          final asset = assets[idx];
                          final date = asset['created_at'] != null
                              ? DateTime.tryParse(asset['created_at'].toString())
                              : null;
                          final ownerships = (asset['ownerships'] as List?) ?? [];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        asset['name'] ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      if (date != null)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Value: FRw ${asset['value'] ?? '-'}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Ownership Breakdown:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  if (ownerships.isEmpty)
                                    const Text(
                                      'No ownership data.',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ...ownerships.map(
                                    (o) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              o['name'] ?? '-',
                                              style: const TextStyle(fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              '${o['percentage']}%',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'FRw ${(o['amount'] ?? 0).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: showAddAssetForm,
                            child: const Text('Add Asset'),
                          ),
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
