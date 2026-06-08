import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/domain/entities/status.dart';
import 'package:zaxo/presentation/blocs/auth/auth_bloc.dart';
import 'package:zaxo/presentation/blocs/auth/auth_state.dart';
import 'package:zaxo/presentation/blocs/status/status_bloc.dart';
import 'package:zaxo/presentation/blocs/status/status_event.dart';
import 'package:zaxo/presentation/blocs/status/status_state.dart';
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
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<StatusBloc, StatusState>(
        builder: (context, state) {
          if (state is StatusLoading || state is StatusInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is StatusError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context
                        .read<StatusBloc>()
                        .add(const StatusLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is StatusLoaded) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
            final statusesByUser = state.statusesByUser;

            // Separate my statuses and others' statuses
            final myStatuses = statusesByUser[currentUserId] ?? <Status>[];
            final otherUsersStatuses = Map<String, List<Status>>.from(statusesByUser)
              ..remove(currentUserId);

            // Split into recent (unviewed) and viewed
            final recentStatuses = <String, List<Status>>{};
            final viewedStatuses = <String, List<Status>>{};

            for (final entry in otherUsersStatuses.entries) {
              final allViewed = entry.value.every((s) => s.isViewedByMe);
              if (allViewed) {
                viewedStatuses[entry.key] = entry.value;
              } else {
                recentStatuses[entry.key] = entry.value;
              }
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // My Status
                _MyStatusTile(
                  myStatuses: myStatuses,
                  onTapCreate: () => context.go('/status/create'),
                  onTapView: () => context.go('/status/view/$currentUserId'),
                ),

                Divider(
                  color: AppColors.outline.withValues(alpha: 0.2),
                  indent: 16,
                  endIndent: 16,
                ),

                // Recent updates header
                if (recentStatuses.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Recent updates',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...recentStatuses.entries.map(
                    (entry) => _StatusUserTile(
                      userId: entry.key,
                      statuses: entry.value,
                      isViewed: false,
                    ),
                  ),
                ],

                // Viewed updates
                if (viewedStatuses.isNotEmpty) ...[
                  if (recentStatuses.isNotEmpty)
                    Divider(
                      color: AppColors.outline.withValues(alpha: 0.2),
                      indent: 16,
                      endIndent: 16,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Viewed updates',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...viewedStatuses.entries.map(
                    (entry) => _StatusUserTile(
                      userId: entry.key,
                      statuses: entry.value,
                      isViewed: true,
                    ),
                  ),
                ],

                // Empty state
                if (otherUsersStatuses.isEmpty && myStatuses.isEmpty)
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 48,
                            color: AppColors.textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No status updates yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to add your first status',
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/status/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}

/// "My Status" tile at the top of the status list.
class _MyStatusTile extends StatelessWidget {
  const _MyStatusTile({
    required this.myStatuses,
    required this.onTapCreate,
    required this.onTapView,
  });

  final List<Status> myStatuses;
  final VoidCallback onTapCreate;
  final VoidCallback onTapView;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthAuthenticated ? authState.user.name : 'Me';
    final userAvatar = authState is AuthAuthenticated
        ? authState.user.avatarUrl
        : null;

    return ListTile(
      leading: Stack(
        children: [
          ProfileAvatar(
            name: userName,
            imageUrl: userAvatar,
            size: AvatarSize.md,
            showStatusRing: myStatuses.isNotEmpty,
            isStatusViewed: false,
            statusSegmentCount: myStatuses.length,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: onTapCreate,
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
          ),
        ],
      ),
      title: const Text(
        'My Status',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        myStatuses.isNotEmpty
            ? 'Tap to view my status'
            : 'Tap to add status update',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      onTap: myStatuses.isNotEmpty ? onTapView : onTapCreate,
    );
  }
}

/// A tile representing a user's status group in the list.
class _StatusUserTile extends StatelessWidget {
  const _StatusUserTile({
    required this.userId,
    required this.statuses,
    required this.isViewed,
  });

  final String userId;
  final List<Status> statuses;
  final bool isViewed;

  @override
  Widget build(BuildContext context) {
    final latestStatus = statuses.first;
    final timeAgo = _formatTimeAgo(latestStatus.createdAt);

    return ListTile(
      leading: ProfileAvatar(
        name: latestStatus.userName ?? userId,
        imageUrl: latestStatus.userPhotoUrl,
        size: AvatarSize.md,
        showStatusRing: true,
        isStatusViewed: isViewed,
        statusSegmentCount: statuses.length,
      ),
      title: Text(
        latestStatus.userName ?? userId,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        timeAgo,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      onTap: () => context.go('/status/view/$userId'),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
