import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = [
      _Contact('Alex Chen', 'Building cool stuff 🚀', true),
      _Contact('Design Team', 'Creative minds at work', false),
      _Contact('Dev Community', 'Code, learn, share', false),
      _Contact('Emma Davis', 'Photography enthusiast 📸', false),
      _Contact('James Park', 'Music lover 🎵', true),
      _Contact('Lisa Wang', 'Travel & adventure 🌍', true),
      _Contact('Mike Johnson', 'Coffee addict ☕', false),
      _Contact('Sarah Wilson', 'Living my best life ✨', true),
      _Contact('Zaxo AI', 'Your AI assistant', true),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Select Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        children: [
          // New group
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.group, color: AppColors.primary, size: 20),
            ),
            title: const Text('New group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
            onTap: () {},
          ),

          // New community
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.public, color: AppColors.secondary, size: 20),
            ),
            title: const Text('New community', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
            onTap: () {},
          ),

          Divider(color: AppColors.outline.withValues(alpha: 0.2)),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Contacts on Zaxo',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          ...contacts.map((contact) => ListTile(
            leading: ProfileAvatar(
              name: contact.name,
              size: AvatarSize.md,
              isOnline: contact.isOnline,
              showOnlineIndicator: contact.isOnline,
            ),
            title: Text(contact.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
            subtitle: Text(contact.about, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            onTap: () => context.go('/chat/${contact.name}'),
          )),
        ],
      ),
    );
  }
}

class _Contact {
  final String name;
  final String about;
  final bool isOnline;

  const _Contact(this.name, this.about, this.isOnline);
}
