import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class InterestTab extends StatefulWidget {
  const InterestTab({super.key});

  @override
  State<InterestTab> createState() => _InterestTabState();
}

class _InterestTabState extends State<InterestTab> {
  List<dynamic> interests = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchInterestData();
  }

  Future<void> fetchInterestData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final url = '$backendBaseUrl/api/admin/report/interests';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          interests = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to fetch interest data.\nStatus: ${response.statusCode}\nBody: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Exception occurred while fetching interest data: $e';
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
    if (interests.isEmpty) {
      return const Center(child: Text('No interest data available.'));
    }

    return RefreshIndicator(
      onRefresh: fetchInterestData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: interests.length,
        itemBuilder: (context, index) {
          final interest = interests[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            child: ListTile(
              title: Text('Rate: ${interest['rate']}%'),
              subtitle: Text('From: ${interest['start_date']} To: ${interest['end_date'] ?? 'Present'}'),
            ),
          );
        },
      ),
    );
  }
}
