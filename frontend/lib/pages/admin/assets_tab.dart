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

  @override
  void initState() {
    super.initState();
    fetchAssets();
  }

  Future<void> fetchAssets() async {
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

  Future<void> addAsset() async {
    final name = nameController.text.trim();
    final value = double.tryParse(valueController.text.trim()) ?? 0;
    if (name.isEmpty || value <= 0) {
      setState(() {
        errorMsg = 'Enter valid name and value.';
      });
      return;
    }
    setState(() {
      errorMsg = null;
    });
    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/admin/asset'),

      body: jsonEncode({
        'name': name,
        'value': value,
        'ownerships': [], // Ownership assignment can be added later
      }),
    );
    if (response.statusCode == 201) {
      setState(() {
        showForm = false;
      });
      nameController.clear();
      valueController.clear();
      fetchAssets();
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
                                  showForm = false;
                                }),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: addAsset,
                                child: const Text('Add Asset'),
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
                      child: const Text('Add Asset'),
                    ),
                  ],
                ),
              ),
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
                                  (o) =>
                                      Text('${o['name']}: ${o['percentage']}%'),
                                )
                                .toList()),
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
