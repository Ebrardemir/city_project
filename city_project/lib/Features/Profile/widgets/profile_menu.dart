import 'package:flutter/material.dart';

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key});

  Widget _tile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1565C0)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _tile(Icons.list_alt, "İhbarlarım"),
        _tile(Icons.favorite, "Desteklediklerim"),
        _tile(Icons.settings, "Ayarlar"),
        _tile(Icons.logout, "Çıkış Yap"),
      ],
    );
  }
}