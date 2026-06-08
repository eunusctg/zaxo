import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Profile card
          ListTile(
            leading: const ProfileAvatar(name: 'Me', size: AvatarSize.lg),
            title: const Text('John Doe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
            subtitle: Text('Hey there! I am using Zaxo 💜', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            trailing: Icon(Icons.qr_code, color: AppColors.textSecondary),
            onTap: () => context.go('/profile'),
          ),

          Divider(color: AppColors.outline.withValues(alpha: 0.2)),

          _sectionHeader('Account'),
          _settingItem(Icons.key, 'Privacy', 'Last seen, profile photo, about'),
          _settingItem(Icons.security, 'Security', 'Lock app, fingerprint, two-step verification'),
          _settingItem(Icons.pin, 'Two-step verification', 'Add extra security to your account'),
          _settingItem(Icons.phone_android, 'Change number', 'Change your registered phone number'),

          _sectionHeader('Chats'),
          _settingItem(Icons.palette, 'Theme', 'Dark'),
          _settingItem(Icons.wallpaper, 'Wallpaper', 'Default'),
          _settingItem(Icons.chat, 'Chat history', 'Backup, export, clear all chats'),
          _settingItem(Icons.cloud_upload, 'Backup', 'Last backup: Never'),

          _sectionHeader('Notifications'),
          _settingItem(Icons.notifications, 'Message notifications', 'On'),
          _settingItem(Icons.group, 'Group notifications', 'On'),
          _settingItem(Icons.call, 'Call notifications', 'On'),

          _sectionHeader('Storage and Data'),
          _settingItem(Icons.storage, 'Storage usage', '1.2 GB used'),
          _settingItem(Icons.network_cell, 'Network usage', '5.8 GB sent, 3.2 GB received'),

          _sectionHeader('Help'),
          _settingItem(Icons.help_outline, 'Help center', 'FAQ, contact us'),
          _settingItem(Icons.info_outline, 'About Zaxo', 'v1.0.0'),
          _settingItem(Icons.privacy_tip, 'Privacy policy', ''),

          const SizedBox(height: 16),

          // Log out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => context.go('/auth'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error),
                foregroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
              ),
              child: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              'from\nzaxo.eu.cc',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _settingItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right, color: AppColors.outline, size: 20),
      onTap: () {},
    );
  }
}
