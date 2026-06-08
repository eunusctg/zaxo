import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';
import 'package:zaxo/domain/entities/call_types.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  CallFilter _selectedFilter = CallFilter.all;

  final List<_DemoCall> _calls = const [
    _DemoCall(name: 'Sarah Wilson', type: CallType.audio, status: CallStatus.ended, isOutgoing: true, time: 'Today, 2:30 PM', duration: '05:32'),
    _DemoCall(name: 'Alex Chen', type: CallType.video, status: CallStatus.missed, isOutgoing: false, time: 'Today, 1:15 PM', duration: null),
    _DemoCall(name: 'Emma Davis', type: CallType.audio, status: CallStatus.ended, isOutgoing: false, time: 'Today, 11:00 AM', duration: '12:45'),
    _DemoCall(name: 'James Park', type: CallType.video, status: CallStatus.ended, isOutgoing: true, time: 'Yesterday, 5:00 PM', duration: '32:10'),
    _DemoCall(name: 'Lisa Wang', type: CallType.audio, status: CallStatus.missed, isOutgoing: false, time: 'Yesterday, 3:30 PM', duration: null),
    _DemoCall(name: 'Mike Johnson', type: CallType.video, status: CallStatus.ended, isOutgoing: true, time: 'Mon, 9:00 AM', duration: '08:20'),
    _DemoCall(name: 'Design Team', type: CallType.audio, status: CallStatus.ended, isOutgoing: true, time: 'Sun, 4:00 PM', duration: '45:02', isGroup: true),
  ];

  List<_DemoCall> get _filteredCalls {
    switch (_selectedFilter) {
      case CallFilter.all:
        return _calls;
      case CallFilter.missed:
        return _calls.where((c) => c.status == CallStatus.missed).toList();
      case CallFilter.outgoing:
        return _calls.where((c) => c.isOutgoing && c.status != CallStatus.missed).toList();
      case CallFilter.incoming:
        return _calls.where((c) => !c.isOutgoing && c.status != CallStatus.missed).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCalls;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Calls',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white),
        ),
        actions: [
          IconButton(icon: Icon(Icons.search, color: AppColors.textSecondary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: CallFilter.values.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    backgroundColor: AppColors.surfaceVariant,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.outline,
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
                    child: Text(
                      'No calls found',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
      case CallFilter.all: return 'All';
      case CallFilter.missed: return 'Missed';
      case CallFilter.outgoing: return 'Outgoing';
      case CallFilter.incoming: return 'Incoming';
    }
  }
}

class _CallItem extends StatelessWidget {
  const _CallItem({required this.call});
  final _DemoCall call;

  @override
  Widget build(BuildContext context) {
    final isMissed = call.status == CallStatus.missed;
    final iconColor = isMissed
        ? AppColors.error
        : call.isOutgoing
            ? AppColors.secondary
            : AppColors.primary;
    final icon = call.isOutgoing
        ? Icons.call_made
        : isMissed
            ? Icons.call_received
            : Icons.call_received;

    return ListTile(
      leading: ProfileAvatar(
        name: call.name,
        size: AvatarSize.md,
      ),
      title: Text(
        call.name,
        style: TextStyle(
          color: isMissed ? AppColors.error : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Icon(call.type == CallType.video ? Icons.videocam : Icons.call, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            call.duration != null ? '${call.time} · ${call.duration}' : call.time,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          call.type == CallType.video ? Icons.videocam : Icons.call,
          color: AppColors.primary,
        ),
        onPressed: () => context.go('/call/audio/call_$call'),
      ),
    );
  }
}

class _DemoCall {
  final String name;
  final CallType type;
  final CallStatus status;
  final bool isOutgoing;
  final String time;
  final String? duration;
  final bool isGroup;

  const _DemoCall({
    required this.name,
    required this.type,
    required this.status,
    required this.isOutgoing,
    required this.time,
    this.duration,
    this.isGroup = false,
  });
}
