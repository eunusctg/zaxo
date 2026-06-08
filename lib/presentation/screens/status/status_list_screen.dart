import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class StatusListScreen extends StatelessWidget {
  const StatusListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Status',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white),
        ),
        actions: [
          IconButton(icon: Icon(Icons.search, color: AppColors.textSecondary), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert, color: AppColors.textSecondary), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // My Status
          ListTile(
            leading: Stack(
              children: [
                const ProfileAvatar(name: 'Me', size: AvatarSize.md),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            title: const Text('My Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: Text('Tap to add status update', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            onTap: () => context.go('/status/create'),
          ),

          Divider(color: AppColors.outline.withValues(alpha: 0.2), indent: 16, endIndent: 16),

          // Recent updates header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Recent updates',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          // Status items
          _statusItem(context, 'Sarah Wilson', 'Today, 10:30 AM', false, 2),
          _statusItem(context, 'Alex Chen', 'Today, 9:15 AM', false, 1),
          _statusItem(context, 'Emma Davis', 'Today, 8:00 AM', true, 1),
          _statusItem(context, 'Lisa Wang', 'Yesterday, 11:45 PM', false, 3),
          _statusItem(context, 'Design Team', 'Yesterday, 6:30 PM', true, 1),

          Divider(color: AppColors.outline.withValues(alpha: 0.2), indent: 16, endIndent: 16),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Viewed updates',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          _statusItem(context, 'James Park', 'Yesterday, 3:20 PM', true, 1),
          _statusItem(context, 'Mike Johnson', 'Yesterday, 1:00 PM', true, 1),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/status/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget _statusItem(BuildContext context, String name, String time, bool isViewed, int count) {
    return ListTile(
      leading: ProfileAvatar(
        name: name,
        size: AvatarSize.md,
        showStatusRing: true,
        isStatusViewed: isViewed,
        statusSegmentCount: count,
      ),
      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(time, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      onTap: () => context.go('/status/view/$name'),
    );
  }
}
