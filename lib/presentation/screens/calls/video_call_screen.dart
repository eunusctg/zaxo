import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/presentation/blocs/call/call_bloc.dart';
import 'package:zaxo/presentation/blocs/call/call_event.dart';
import 'package:zaxo/presentation/blocs/call/call_state.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key, required this.chatId});
  final String chatId;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  Timer? _durationTimer;
  int _callDuration = 0;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  String get _formattedDuration {
    final mins = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final secs = (_callDuration % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _endCall() {
    _durationTimer?.cancel();
    final state = context.read<CallBloc>().state;
    if (state is CallOngoing) {
      context.read<CallBloc>().add(CallEnded(callId: state.callId));
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallEndedState) {
          _durationTimer?.cancel();
          context.pop();
        }
      },
      builder: (context, state) {
        // Determine the other user name
        String otherUserName = 'User';
        if (state is CallOutgoing) {
          otherUserName = state.receiver.name;
        } else if (state is CallIncoming) {
          otherUserName = state.caller.name;
        } else {
          otherUserName = widget.chatId;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Remote video (full screen placeholder)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.background, AppColors.surface],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProfileAvatar(
                        name: otherUserName,
                        size: AvatarSize.xl,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        otherUserName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formattedDuration,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              // Self view (PiP)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
                  ),
                  child: _isVideoOff
                      ? const Center(
                          child:
                              ProfileAvatar(name: 'Me', size: AvatarSize.lg),
                        )
                      : const Center(
                          child: Icon(Icons.videocam,
                              size: 36, color: AppColors.textSecondary),
                        ),
                ),
              ),

              // Top bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.secondary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formattedDuration,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ControlBtn(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        isActive: _isMuted,
                        onPressed: () => setState(() => _isMuted = !_isMuted),
                      ),
                      _ControlBtn(
                        icon: _isVideoOff
                            ? Icons.videocam_off
                            : Icons.videocam,
                        isActive: _isVideoOff,
                        onPressed: () =>
                            setState(() => _isVideoOff = !_isVideoOff),
                      ),
                      _ControlBtn(
                        icon: _isFrontCamera
                            ? Icons.flip_camera_android
                            : Icons.flip_camera_android_outlined,
                        isActive: false,
                        onPressed: () =>
                            setState(() => _isFrontCamera = !_isFrontCamera),
                      ),
                      _ControlBtn(
                        icon: Icons.volume_up,
                        isActive: false,
                        onPressed: () {},
                      ),
                      GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.4),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.call_end,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: isActive ? Colors.white : AppColors.textSecondary,
            size: 22),
      ),
    );
  }
}
