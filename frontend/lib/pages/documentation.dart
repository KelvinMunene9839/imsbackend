import 'package:flutter/material.dart';

class DocumentationPage extends StatelessWidget {
  const DocumentationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMS User Documentation'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Welcome to the IMS (Investment Management System) User Guide',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Getting Started'),
          _sectionText('1. Log in with your credentials.\n2. Navigate using the bottom tabs: Dashboard, Transactions, Profile, etc.'),
          const SizedBox(height: 16),
          _sectionTitle('Investor Dashboard'),
          _sectionText('• View your total contributions, percentage share, and recent transactions.\n• Click the profile image or pen icon to update your name, email, or profile picture.'),
          const SizedBox(height: 16),
          _sectionTitle('Profile Update'),
          _sectionText('1. Tap your profile image or the edit icon.\n2. Select a new image and/or update your name/email.\n3. Tap Save. Your profile will update instantly.'),
          const SizedBox(height: 16),
          _sectionTitle('Transactions'),
          _sectionText('• View your recent activity.\n• Tap "View All" to see your full transaction history.'),
          const SizedBox(height: 16),
          _sectionTitle('Admin Features'),
          _sectionText('Admins can manage investors, assets, and interest rates from the Admin Dashboard.'),
          const SizedBox(height: 16),
          _sectionTitle('Troubleshooting'),
          _sectionText('• If you encounter errors, check your internet connection.\n• For profile image issues, ensure your image is under 2MB and in PNG/JPG format.\n• Contact support for further help.'),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'For more help, contact your system administrator.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF18332B)),
      );

  Widget _sectionText(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, height: 1.5),
      );
}
