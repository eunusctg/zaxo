import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';

import 'package:zaxo/domain/entities/call.dart';
import 'package:zaxo/domain/entities/call_types.dart';
import 'package:zaxo/presentation/blocs/call/call_bloc.dart';
import 'package:zaxo/presentation/blocs/call/call_event.dart';
import 'package:zaxo/presentation/blocs/call/call_state.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Calls',
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
        ],
      ),
      body: BlocBuilder<CallBloc, CallState>(
        builder: (context, state) {
          if (state is CallInitial || state is CallOngoing) {
            // Still loading or in a call — show history if available
          }

          if (state is CallError) {
            final previousState = state;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    previousState.message,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context
                        .read<CallBloc>()
                        .add(const CallHistoryLoaded()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CallHistoryLoadedState) {
            final filtered = state.filteredCalls;

            return Column(
              children: [
                // Filter chips
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    children: CallFilter.values.map((filter) {
                      final isSelected = filter == state.filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_filterLabel(filter)),
                          selected: isSelected,
                          onSelected: (_) => context
                              .read<CallBloc>()
                              .add(CallFilterChanged(filter: filter)),
                          backgroundColor: AppColors.surfaceVariant,
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.outline,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Call list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.call_end,
                                size: 48,
                                color:
                                    AppColors.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No calls found',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            color: AppColors.outline.withValues(alpha: 0.2),
                            indent: 76,
                            endIndent: 16,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final call = filtered[index];
                            return _CallItem(call: call);
                          },
                        ),
                ),
              ],
            );
          }

          // Initial / loading state
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
    );
  }

  String _filterLabel(CallFilter filter) {
    switch (filter) {
      case CallFilter.all:
        return 'All';
      case CallFilter.missed:
        return 'Missed';
      case CallFilter.outgoing:
        return 'Outgoing';
      case CallFilter.incoming:
        return 'Incoming';
    }
  }
}

class _CallItem extends StatelessWidget {
  const _CallItem({required this.call});
  final Call call;

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOutgoing = call.callerId == currentUserId;
    final isMissed = call.isMissed;
    final isVideo = call.type == CallType.video;

    final iconColor = isMissed
        ? AppColors.error
        : isOutgoing
            ? AppColors.secondary
            : AppColors.primary;
    final directionIcon = isOutgoing
        ? Icons.call_made
        : isMissed
            ? Icons.call_received
            : Icons.call_received;

    // Determine the other user in this call
    final otherUserId = isOutgoing ? call.receiverId : call.callerId;

    return ListTile(
      leading: ProfileAvatar(
        name: otherUserId,
        size: AvatarSize.md,
      ),
      title: Text(
        otherUserId,
        style: TextStyle(
          color: isMissed ? AppColors.error : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(directionIcon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Icon(
            isVideo ? Icons.videocam : Icons.call,
            size: 12,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            call.duration != null
                ? '${_formatTime(call.createdAt)} · ${_formatDuration(call.duration!)}'
                : _formatTime(call.createdAt),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          isVideo ? Icons.videocam : Icons.call,
          color: AppColors.primary,
        ),
        onPressed: () {
          final route =
              isVideo ? '/call/video/${call.id}' : '/call/audio/${call.id}';
          context.go(route);
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return 'Today, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
