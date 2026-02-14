import 'package:city_project/Features/Login/model/user_model.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final role = user.role.toLowerCase();
    
    // Rol bazlı renk ve ikon belirleme
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;
    
    if (role == 'admin') {
      badgeColor = Colors.purple;
      badgeIcon = Icons.admin_panel_settings;
      badgeText = '⚙️ Admin';
    } else if (role == 'municipality') {
      badgeColor = Colors.deepOrange;
      badgeIcon = Icons.business;
      badgeText = '🏛️ Belediye';
    } else {
      badgeColor = Colors.blue;
      badgeIcon = Icons.person;
      badgeText = '👤 Vatandaş';
    }
    
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
              const SizedBox(height: 4),
              // Rol badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      badgeIcon,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    if (user.city != null) ...[
                      const Text(' • ', style: TextStyle(color: Colors.white70)),
                      Text(
                        user.city!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ],
                ),
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
