import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class RankingsTab extends StatefulWidget {
  const RankingsTab({super.key});

  @override
  State<RankingsTab> createState() => _RankingsTabState();
}

class _RankingsTabState extends State<RankingsTab> {
  List<dynamic> rankings = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchRankingsData();
  }

  Future<void> fetchRankingsData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final url = '$backendBaseUrl/api/admin/report/contributions/monthly';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          rankings = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to fetch rankings data.\nStatus: ${response.statusCode}\nBody: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Exception occurred while fetching rankings data: $e';
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
    if (rankings.isEmpty) {
      return const Center(child: Text('No rankings data available.'));
    }

    return RefreshIndicator(
      onRefresh: fetchRankingsData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          final rank = rankings[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            child: ListTile(
              title: Text(rank['name'] ?? 'Unknown'),
              subtitle: Text('Month: ${rank['month'] ?? 'N/A'}, Year: ${rank['year'] ?? 'N/A'}'),
              trailing: Text('Total: ₦${rank['total'] ?? '0'}'),
            ),
          );
        },
      ),
    );
  }
}
