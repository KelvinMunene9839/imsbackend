import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String amount;
  final VoidCallback? onViewProfile;

  const ProfileCard({
    super.key,
    required this.name,
    required this.amount,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF18332B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF18332B)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF18332B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onViewProfile,
              child: const Text('View Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
