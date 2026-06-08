import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/core/constants/app_animations.dart';

/// Real-time voice waveform visualization widget.
///
/// Features:
/// - Bars with gradient fill based on frequency data
/// - Glow effect on active bars
/// - Play/pause button with morph animation
/// - Progress slider with gradient track
class VoiceWaveform extends StatefulWidget {
  const VoiceWaveform({
    super.key,
    this.barCount = 40,
    this.barWidth = 3.0,
    this.barGap = 2.0,
    this.maxBarHeight = 48.0,
    this.minBarHeight = 4.0,
    this.isPlaying = false,
    this.progress = 0.0,
    this.amplitudeData = const [],
    this.onPlayPause,
    this.onSeek,
    this.showControls = true,
    this.showProgressSlider = true,
    this.duration = Duration.zero,
    this.elapsed = Duration.zero,
  });

  /// Number of bars in the waveform.
  final int barCount;

  /// Width of each bar.
  final double barWidth;

  /// Gap between bars.
  final double barGap;

  /// Maximum height of a bar.
  final double maxBarHeight;

  /// Minimum height of a bar.
  final double minBarHeight;

  /// Whether audio is currently playing.
  final bool isPlaying;

  /// Playback progress from 0.0 to 1.0.
  final double progress;

  /// Amplitude data (0.0–1.0 per bar). If empty, generates a pattern.
  final List<double> amplitudeData;

  /// Callback when play/pause is tapped.
  final VoidCallback? onPlayPause;

  /// Callback when the user seeks via the progress slider.
  final ValueChanged<double>? onSeek;

  /// Whether to show play/pause and time labels.
  final bool showControls;

  /// Whether to show the progress slider.
  final bool showProgressSlider;

  /// Total duration of the audio.
  final Duration duration;

  /// Elapsed playback time.
  final Duration elapsed;

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with TickerProviderStateMixin {
  late List<double> _bars;
  late AnimationController _glowController;
  late AnimationController _morphController;

  @override
  void initState() {
    super.initState();
    _bars = _generateBars();
    _glowController = AnimationController(
      vsync: this,
      duration: AppAnimations.pulseDuration,
    )..repeat(reverse: true);
    _morphController = AnimationController(
      vsync: this,
      duration: AppAnimations.durationNormal,
    );
    if (widget.isPlaying) {
      _morphController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amplitudeData != widget.amplitudeData) {
      _bars = _generateBars();
    }
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _morphController.forward();
      } else {
        _morphController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  List<double> _generateBars() {
    if (widget.amplitudeData.isNotEmpty) {
      return widget.amplitudeData
          .take(widget.barCount)
          .toList()
          .padOrTruncate(widget.barCount, 0.3);
    }
    // Generate a realistic waveform pattern.
    final random = math.Random(42);
    return List.generate(widget.barCount, (i) {
      final center = widget.barCount / 2;
      final distFromCenter = (i - center).abs() / center;
      final base = 0.4 + 0.6 * (1.0 - distFromCenter * distFromCenter);
      return (base * (0.6 + random.nextDouble() * 0.4)).clamp(0.1, 1.0);
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform bars
        SizedBox(
          height: widget.maxBarHeight + 16,
          child: AnimatedBuilder(
            animation: Listenable.merge([_glowController, _morphController]),
            builder: (context, _) {
              return CustomPaint(
                size: Size(
                  widget.barCount * (widget.barWidth + widget.barGap),
                  widget.maxBarHeight + 16,
                ),
                painter: _WaveformPainter(
                  bars: _bars,
                  barWidth: widget.barWidth,
                  barGap: widget.barGap,
                  maxBarHeight: widget.maxBarHeight,
                  minBarHeight: widget.minBarHeight,
                  progress: widget.progress,
                  glowValue: _glowController.value,
                  isPlaying: widget.isPlaying,
                ),
              );
            },
          ),
        ),

        if (widget.showControls) ...[
          const SizedBox(height: AppDimensions.paddingSm),
          _buildControls(),
        ],

        if (widget.showProgressSlider) ...[
          const SizedBox(height: AppDimensions.paddingXs),
          _buildProgressSlider(),
        ],
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Elapsed time
        Text(
          _formatDuration(widget.elapsed),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),

        const SizedBox(width: AppDimensions.paddingMd),

        // Play/Pause button with morph animation
        GestureDetector(
          onTap: widget.onPlayPause,
          child: AnimatedBuilder(
            animation: _morphController,
            builder: (context, _) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _PlayPausePainter(
                    progress: _morphController.value,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(width: AppDimensions.paddingMd),

        // Total duration
        Text(
          _formatDuration(widget.duration),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }

  Widget _buildProgressSlider() {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.outline.withValues(alpha: 0.3),
        thumbColor: AppColors.primary,
      ),
      child: Slider(
        value: widget.progress.clamp(0.0, 1.0),
        onChanged: widget.onSeek,
      ),
    );
  }
}

/// CustomPainter for the waveform bars.
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.barWidth,
    required this.barGap,
    required this.maxBarHeight,
    required this.minBarHeight,
    required this.progress,
    required this.glowValue,
    required this.isPlaying,
  });

  final List<double> bars;
  final double barWidth;
  final double barGap;
  final double maxBarHeight;
  final double minBarHeight;
  final double progress;
  final double glowValue;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final totalWidth = bars.length * (barWidth + barGap);
    final offsetX = (size.width - totalWidth) / 2;

    for (int i = 0; i < bars.length; i++) {
      final x = offsetX + i * (barWidth + barGap);
      final normalizedAmplitude = bars[i].clamp(0.0, 1.0);
      double barHeight = minBarHeight +
          (maxBarHeight - minBarHeight) * normalizedAmplitude;

      // Add subtle animation when playing.
      if (isPlaying) {
        final wobble = math.sin(glowValue * math.pi * 2 + i * 0.3) * 4;
        barHeight = (barHeight + wobble).clamp(minBarHeight, maxBarHeight);
      }

      final isPastProgress = (i / bars.length) <= progress;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barWidth / 2),
      );

      // Gradient for played bars.
      final paint = Paint()
        ..style = PaintingStyle.fill;

      if (isPastProgress) {
        paint.shader = LinearGradient(
          colors: const [AppColors.primary, AppColors.secondary],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight,
        ));

        // Glow effect for active bars.
        if (isPlaying) {
          final glowPaint = Paint()
            ..color = AppColors.primary.withValues(alpha: 0.15 + glowValue * 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawRRect(rect, glowPaint);
        }
      } else {
        paint.color = AppColors.outline.withValues(alpha: 0.3);
      }

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowValue != glowValue ||
        oldDelegate.isPlaying != isPlaying ||
        !listEquals(oldDelegate.bars, bars);
  }

  static bool listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// CustomPainter that morphs between play and pause icons.
class _PlayPausePainter extends CustomPainter {
  _PlayPausePainter({
    required this.progress,
    required this.color,
  });

  /// 0.0 = play, 1.0 = pause
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final s = size.width * 0.3;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Play triangle → Pause bars morph
    // Simplified: cross-fade between play and pause shapes.
    if (progress < 0.5) {
      // Draw play triangle
      final playScale = 1.0 - progress * 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(playScale);

      final path = Path()
        ..moveTo(-s * 0.4, -s * 0.5)
        ..lineTo(s * 0.5, 0)
        ..lineTo(-s * 0.4, s * 0.5)
        ..close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }

    if (progress > 0.5) {
      // Draw pause bars
      final pauseScale = (progress - 0.5) * 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(pauseScale);

      final barWidth = s * 0.25;
      final barHeight = s * 0.7;
      final gap = s * 0.2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(-gap / 2 - barWidth / 2, 0),
            width: barWidth,
            height: barHeight,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(gap / 2 + barWidth / 2, 0),
            width: barWidth,
            height: barHeight,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PlayPausePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Extension to pad or truncate a list.
extension _ListExtension<T> on List<T> {
  List<T> padOrTruncate(int length, T filler) {
    if (this.length >= length) return sublist(0, length);
    return [...this, ...List.filled(length - this.length, filler)];
  }
}
