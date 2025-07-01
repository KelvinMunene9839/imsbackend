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
    double screenWidth = MediaQuery.of(context).size.width;
    double paddingValue = 20.0;
    double fontSizeName = 18.0;
    double fontSizeAmount = 16.0;
    double spacing = 16.0;
    bool useColumnLayout = false;

    if (screenWidth < 400) {
      paddingValue = 12.0;
      fontSizeName = 14.0;
      fontSizeAmount = 12.0;
      spacing = 8.0;
      useColumnLayout = true;
    } else if (screenWidth < 600) {
      paddingValue = 16.0;
      fontSizeName = 16.0;
      fontSizeAmount = 14.0;
      spacing = 12.0;
    }

    return Card(
      color: const Color(0xFF18332B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(paddingValue),
        child: useColumnLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF18332B)),
                  ),
                  SizedBox(height: spacing),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: fontSizeName,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: spacing / 2),
                  Text(
                    amount,
                    style: TextStyle(fontSize: fontSizeAmount, color: Colors.white70),
                  ),
                  SizedBox(height: spacing),
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
              )
            : Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF18332B)),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: fontSizeName,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: spacing / 4),
                        Text(
                          amount,
                          style: TextStyle(fontSize: fontSizeAmount, color: Colors.white70),
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
