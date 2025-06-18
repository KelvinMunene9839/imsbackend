import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';
import '../../widgets/stat_card.dart';

class InterestRatesTab extends StatefulWidget {
  const InterestRatesTab({super.key});

  @override
  State<InterestRatesTab> createState() => _InterestRatesTabState();
}

class _InterestRatesTabState extends State<InterestRatesTab> {
  List<dynamic> rates = [];
  bool isLoading = true;
  final TextEditingController rateController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  bool showForm = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchRates();
  }

  Future<void> fetchRates() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.get(
      Uri.parse('$backendBaseUrl/api/admin/interest-rates'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      setState(() {
        rates = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addRate() async {
    final rate = double.tryParse(rateController.text.trim()) ?? 0;
    final startDate = startDateController.text.trim();
    final endDate = endDateController.text.trim().isEmpty
        ? null
        : endDateController.text.trim();
    if (rate <= 0 || startDate.isEmpty) {
      setState(() {
        errorMsg = 'Rate and start date are required.';
      });
      return;
    }
    setState(() {
      errorMsg = null;
    });
    final response = await http.post(
      Uri.parse('$backendBaseUrl/api/admin/interest-rate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'rate': rate,
        'start_date': startDate,
        'end_date': endDate,
      }),
    );
    if (response.statusCode == 201) {
      setState(() {
        showForm = false;
      });
      rateController.clear();
      startDateController.clear();
      endDateController.clear();
      fetchRates();
    } else {
      setState(() {
        errorMsg = 'Failed to add interest rate.';
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Interest Rates',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18332B),
                  ),
                ),
              ),
              Row(
                children: [
                  if (rates.isNotEmpty)
                    StatCard(
                      title: 'Current Rate',
                      value: '${rates[0]['rate']}%',
                      icon: Icons.percent,
                      color: const Color(0xFF18332B),
                    ),
                  const SizedBox(width: 16),
                  if (rates.length > 1)
                    StatCard(
                      title: 'Previous Rate',
                      value: '${rates[1]['rate']}%',
                      icon: Icons.percent,
                      color: Colors.green,
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
                            controller: rateController,
                            decoration: const InputDecoration(
                              labelText: 'Rate (%)',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: startDateController,
                            decoration: const InputDecoration(
                              labelText: 'Start Date (YYYY-MM-DD)',
                            ),
                          ),
                          TextField(
                            controller: endDateController,
                            decoration: const InputDecoration(
                              labelText: 'End Date (YYYY-MM-DD, optional)',
                            ),
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
                                onPressed: addRate,
                                child: const Text('Add Rate'),
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
                      child: const Text('Add Interest Rate'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: rates.length,
                  itemBuilder: (context, idx) {
                    final r = rates[idx];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Rate: ${r['rate']}%'),
                        subtitle: Text(
                          'From: ${r['start_date']} To: ${r['end_date'] ?? 'Present'}',
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
