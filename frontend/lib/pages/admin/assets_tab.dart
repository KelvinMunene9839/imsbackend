import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';
import '../../widgets/stat_card.dart';

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

  void showAddAssetForm() async {
    await fetchInvestors();
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
                            final amount = double.tryParse(amountControllers[i].text) ?? 0.0;
                            final percent = totalContribution > 0
                                ? (amount / totalContribution) * 100
                                : 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  Expanded(child: Text(investors[i]['name'])),
                                  SizedBox(
                                    width: 90,
                                    child: TextField(
                                      controller: amountControllers[i],
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Amount'),
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
                          Text('Total: ₦${totalContribution.toStringAsFixed(2)}'),
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
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatCard(
                    title: 'Company A',
                    value: assets.isNotEmpty
                        ? assets[0]['value'].toString()
                        : '-',
                    icon: Icons.business,
                    color: const Color(0xFF18332B),
                  ),
                  const SizedBox(width: 16),
                  StatCard(
                    title: 'Global Fund',
                    value: assets.length > 1
                        ? assets[1]['value'].toString()
                        : '-',
                    icon: Icons.public,
                    color: const Color(0xFF18332B),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, idx) {
                    final asset = assets[idx];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Asset: ${asset['name']}'),
                        subtitle: Text('Value: ${asset['value']}'),
                        isThreeLine: true,
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Ownership:'),
                            ...((asset['ownerships'] as List)
                                .map(
                                  (o) => Text('${o['name']}: ${o['percentage']}%'),
                                )
                                .toList()),
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
          );
  }
}
