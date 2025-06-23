import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_client.dart';
import '../../config.dart';
import '../../widgets/ims_card.dart';

class ContributionsTab extends StatefulWidget {
  const ContributionsTab({super.key});

  @override
  State<ContributionsTab> createState() => _ContributionsTabState();
}

class _ContributionsTabState extends State<ContributionsTab> {
  final ApiClient apiClient = ApiClient(
    baseUrl: '$backendBaseUrl/api/investor',
  );
  List<Map<String, dynamic>> _contributions = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchContributions();
  }

  Future<String?> getInvestorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('investorId');
  }

  Future<void> _fetchContributions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final investorId = await getInvestorId();
      if (investorId == null) {
        setState(() {
          _error = 'No investor ID found. Please log in again.';
          _loading = false;
        });
        return;
      }
      final res = await apiClient.get('/me?id=$investorId');
      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(res.body));
        setState(() {
          _contributions = List<Map<String, dynamic>>.from(
            data['transactions'] ?? [],
          );
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load contributions.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submitContribution() async {
    if (_amountController.text.isEmpty || _selectedDate == null) return;
    setState(() => _submitting = true);
    try {
      final investorId = await getInvestorId();
      if (investorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No investor ID found. Please log in again.'),
          ),
        );
        setState(() => _submitting = false);
        return;
      }
      final res = await apiClient.post('/transaction?id=$investorId', {
        'amount': double.tryParse(_amountController.text) ?? 0,
        'date': _selectedDate!.toIso8601String().substring(0, 10),
      });
      if (res.statusCode == 201) {
        _amountController.clear();
        _selectedDate = null;
        await _fetchContributions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution submitted for approval.')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${res.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record New Contribution',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submitContribution,
                    child: _submitting
                        ? const CircularProgressIndicator()
                        : const Text('Submit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Contribution History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _contributions.isEmpty
                ? const Center(child: Text('No contributions yet.'))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _contributions.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final c = _contributions[i];
                      return ListTile(
                        leading: Icon(
                          c['status'] == 'pending'
                              ? Icons.hourglass_empty
                              : Icons.check_circle,
                          color: c['status'] == 'pending'
                              ? Colors.orange
                              : Colors.green,
                        ),
                        title: Text('Amount: ${c['amount']}'),
                        subtitle: Text(
                          'Date: ${c['date']?.toString().substring(0, 10) ?? ''}',
                        ),
                        trailing: Text(c['status'] ?? ''),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
