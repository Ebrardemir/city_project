import 'package:flutter/material.dart';

class ProfileMenu extends StatelessWidget {
  final VoidCallback onMyReportsTap;
  final VoidCallback onCreateReportTap;
  final VoidCallback onLogoutTap;

  const ProfileMenu({
    super.key,
    required this.onMyReportsTap,
    required this.onCreateReportTap,
    required this.onLogoutTap,
  });

  Widget _tile(IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1565C0)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _tile(Icons.list_alt, "İhbarlarım", onTap: onMyReportsTap),
        _tile(
          Icons.add_circle_outline,
          "İhbar Oluştur",
          onTap: onCreateReportTap,
        ),
        _tile(Icons.logout, "Çıkış Yap", onTap: onLogoutTap),
      ],
    );
  }
}
