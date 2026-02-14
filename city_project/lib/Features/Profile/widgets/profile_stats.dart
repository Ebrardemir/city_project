import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int reports;
  final int supported;
  final int resolved;

  const ProfileStats({
    super.key,
    required this.reports,
    required this.supported,
    required this.resolved,
  });

  Widget _buildCard(String title, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1565C0)),
            const SizedBox(height: 6),
            Text(
              "$value",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildCard("İhbar", reports, Icons.report),
        const SizedBox(width: 10),
        _buildCard("Destek", supported, Icons.favorite),
        const SizedBox(width: 10),
        _buildCard("Çözülen", resolved, Icons.check_circle),
      ],
    );
  }
}