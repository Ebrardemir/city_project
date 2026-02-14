import 'package:flutter/material.dart';
import '../../Login/model/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 35,
          backgroundColor: Color(0xFF1565C0),
          child: Icon(Icons.person, size: 35, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(user.email, style: const TextStyle(color: Colors.grey)),
              Text(
                "${user.role} • ${user.cityName ?? ''}",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        Column(
          children: [
            const Text(
              "Puan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            Text(
              "${user.score}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
