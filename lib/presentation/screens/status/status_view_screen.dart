import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/domain/entities/status.dart';
import 'package:zaxo/presentation/blocs/status/status_bloc.dart';
import 'package:zaxo/presentation/blocs/status/status_event.dart';
import 'package:zaxo/presentation/blocs/status/status_state.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class StatusViewScreen extends StatefulWidget {
  const StatusViewScreen({super.key, required this.userId});
  final String userId;

  @override
  State<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  int _currentIndex = 0;
  List<Status> _userStatuses = [];
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_isPaused) {
          _goToNext();
        }
      });
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  void _goToNext() {
    if (_currentIndex < _userStatuses.length - 1) {
      setState(() => _currentIndex++);
      _startProgress();
    } else {
      context.pop();
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startProgress();
    } else {
      context.pop();
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _progressController.stop();
    } else {
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<StatusBloc, StatusState>(
        builder: (context, state) {
          if (state is! StatusLoaded && state is! StatusViewing) {
            return Container(
              color: AppColors.background,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          // Get statuses for this user
          if (state is StatusLoaded) {
            _userStatuses = state.statuses
                .where((s) => s.userId == widget.userId)
                .toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          }

          if (_userStatuses.isEmpty) {
            return Container(
              color: AppColors.background,
              child: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No statuses available',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Start progress on first build
          if (!_progressController.isAnimating && !_isPaused && _currentIndex == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_progressController.isAnimating) {
                _startProgress();
              }
            });
          }

          // Dispatch StatusViewed for current status
          final currentStatus = _userStatuses[_currentIndex];
          if (!currentStatus.isViewedByMe) {
            context
                .read<StatusBloc>()
                .add(StatusViewed(statusId: currentStatus.id));
          }

          return _buildStatusView(currentStatus);
        },
      ),
    );
  }

  Widget _buildStatusView(Status status) {
    final bgColor = _parseBgColor(status.bgColor);

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.sizeOf(context).width;
          if (details.globalPosition.dx < width / 3) {
            _goToPrevious();
          } else {
            _goToNext();
          }
        },
        onLongPress: _togglePause,
        onLongPressEnd: (_) => _togglePause(),
        child: SafeArea(
          child: Column(
            children: [
              // Progress bars
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(_userStatuses.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            double progress;
                            if (index < _currentIndex) {
                              progress = 1.0;
                            } else if (index == _currentIndex) {
                              progress = _progressController.value;
                            } else {
                              progress = 0.0;
                            }

                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    ProfileAvatar(
                      name: status.userName ?? widget.userId,
                      imageUrl: status.userPhotoUrl,
                      size: AvatarSize.sm,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.userName ?? widget.userId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatTime(status.createdAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Status content
              Expanded(
                child: Center(
                  child: _buildStatusContent(status),
                ),
              ),

              // Reply input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Reply...',
                          hintStyle:
                              TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusContent(Status status) {
    switch (status.type) {
      case StatusMediaType.image:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.mediaUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    status.mediaUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      width: 200,
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image,
                          color: Colors.white54, size: 48),
                    ),
                  ),
                ),
              if (status.caption != null && status.caption!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  status.caption!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ],
          ),
        );
      case StatusMediaType.video:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, color: Colors.white, size: 64),
            SizedBox(height: 12),
            Text(
              'Video status',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        );
      case StatusMediaType.text:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            status.text ?? status.content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Outfit',
              height: 1.3,
            ),
          ),
        );
    }
  }

  Color _parseBgColor(String? bgColorStr) {
    if (bgColorStr == null || bgColorStr.isEmpty) return AppColors.primary;
    if (bgColorStr.startsWith('#') && bgColorStr.length == 7) {
      try {
        return Color(
            0xFF000000 + int.parse(bgColorStr.substring(1), radix: 16));
      } catch (_) {
        return AppColors.primary;
      }
    }
    return AppColors.primary;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
