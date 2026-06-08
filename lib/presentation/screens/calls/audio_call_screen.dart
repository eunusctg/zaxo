import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/presentation/blocs/call/call_bloc.dart';
import 'package:zaxo/presentation/blocs/call/call_event.dart';
import 'package:zaxo/presentation/blocs/call/call_state.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({super.key, required this.chatId});
  final String chatId;

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  Timer? _durationTimer;
  int _callDuration = 0;
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isBluetooth = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
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
        if (state is CallOngoing) {
          // Call is connected — start duration timer
          if (_durationTimer == null || !_durationTimer!.isActive) {
            _startDurationTimer();
          }
        }
        if (state is CallEndedState) {
          _durationTimer?.cancel();
          context.pop();
        }
      },
      builder: (context, state) {
        final callState = state;
        final isConnected = callState is CallOngoing;

        final callStatusText = isConnected ? _formattedDuration : 'Calling...';

        // Determine the other user name
        String otherUserName = 'User';
        if (callState is CallOutgoing) {
          otherUserName = callState.receiver.name;
        } else if (callState is CallOngoing) {
          // We don't have the receiver name in CallOngoing, use chatId as fallback
          otherUserName = widget.chatId;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Avatar with pulse animation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple effect
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(180, 180),
                          painter: _RipplePainter(
                            animation: _rippleController,
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        );
                      },
                    ),

                    // Pulse avatar
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + _pulseController.value * 0.05;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ProfileAvatar(
                              name: otherUserName,
                              size: AvatarSize.xl,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Name
                Text(
                  otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Outfit',
                  ),
                ),

                const SizedBox(height: 8),

                // Status
                Text(
                  callStatusText,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),

                const Spacer(),

                // Call controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        isActive: _isMuted,
                        onPressed: () => setState(() => _isMuted = !_isMuted),
                      ),
                      _CallControlButton(
                        icon: _isSpeaker
                            ? Icons.volume_up
                            : Icons.volume_up_outlined,
                        label: 'Speaker',
                        isActive: _isSpeaker,
                        onPressed: () =>
                            setState(() => _isSpeaker = !_isSpeaker),
                      ),
                      _CallControlButton(
                        icon: Icons.bluetooth,
                        label: 'Bluetooth',
                        isActive: _isBluetooth,
                        onPressed: () =>
                            setState(() => _isBluetooth = !_isBluetooth),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // End call button
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.call_end, color: Colors.white, size: 28),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isActive ? Colors.white : AppColors.textSecondary,
                size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.animation, required this.color});
  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final progress = (animation.value + i * 0.33) % 1.0;
      final radius = 60.0 + progress * 40.0;
      final opacity = (1.0 - progress) * 0.3;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true;
}
