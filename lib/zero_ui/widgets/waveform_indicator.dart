// lib/zero_ui/widgets/waveform_indicator.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class WaveformIndicator extends StatelessWidget {
  const WaveformIndicator({
    required this.soundLevel,
    required this.isListening,
    super.key,
  });

  final double soundLevel;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    if (!isListening) return const SizedBox(height: 70);

    final scale = (1.0 + (soundLevel.clamp(0, 10) / 5)).clamp(1.0, 2.0);

    return SizedBox(
      height: 80,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 60 * scale,
          height: 60 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.terracotta.withValues(alpha: 0.12),
            border: Border.all(
              color: AppTheme.terracotta,
              width: 2.5 * scale,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.mic_rounded,
              color: AppTheme.terracotta,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}