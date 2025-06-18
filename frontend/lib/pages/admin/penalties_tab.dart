import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';
import '../../widgets/stat_card.dart';

class PenaltiesTab extends StatefulWidget {
  const PenaltiesTab({super.key});

  @override
  State<PenaltiesTab> createState() => _PenaltiesTabState();
}

class _PenaltiesTabState extends State<PenaltiesTab> {
  List<dynamic> penalties = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPenalties();
  }

  Future<void> fetchPenalties() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.get(
      Uri.parse('$backendBaseUrl/api/admin/penalties'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      try {
        setState(() {
          penalties = jsonDecode(response.body);
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print('Error parsing penalties JSON: $e');
      }
    } else {
      setState(() {
        isLoading = false;
      });
      print(
        'Failed to fetch penalties: ${response.statusCode} ${response.body}',
      );
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
                  'Penalties',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18332B),
                  ),
                ),
              ),
              if (penalties.isNotEmpty)
                StatCard(
                  title: 'Total Penalties',
                  value: penalties.length.toString(),
                  icon: Icons.warning,
                  color: Colors.red.shade700,
                ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: penalties.length,
                  itemBuilder: (context, idx) {
                    final penalty = penalties[idx];
                    return ListTile(
                      title: Text(penalty['reason'] ?? ''),
                      subtitle: Text('Amount: ${penalty['amount'] ?? ''}'),
                      trailing: Text(penalty['date'] ?? ''),
                    );
                  },
                ),
              ),
            ],
          );
  }
}
