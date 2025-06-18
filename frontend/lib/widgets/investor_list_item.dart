import 'package:flutter/material.dart';

class InvestorListItem extends StatelessWidget {
  final String name;
  final String status;
  final String amount;
  final VoidCallback? onTap;

  const InvestorListItem({
    super.key,
    required this.name,
    required this.status,
    required this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
