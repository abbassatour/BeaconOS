// lib/zero_ui/view/zero_ui_view.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/zero_ui/cubit/zero_ui_cubit.dart';
import 'package:beacon_os/zero_ui/cubit/zero_ui_state.dart';
import 'package:beacon_os/zero_ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ZeroUiView extends StatelessWidget {
  const ZeroUiView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ZeroUiCubit>();

    return BlocBuilder<ZeroUiCubit, ZeroUiState>(
      builder: (context, state) {
        final isEyesFree = state.displayMode == DisplayMode.eyesFree;

        return Scaffold(
          backgroundColor: AppTheme.pureBlack,
          body: HapticCanvas(
            onLongPressStart: cubit.onTouchStarted,
            onLongPressEnd: cubit.onTouchReleased,
            onSwipeUp: cubit.replayLastResponse,
            onSwipeDown: cubit.toggleDisplayMode,
            onTripleTap: cubit.triggerEmergencySos,
            child: SafeArea(
              child: isEyesFree
                  ? _buildEyesFreeMode(state)
                  : _buildVisualHudMode(state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEyesFreeMode(ZeroUiState state) {
    IconData icon = Icons.touch_app_rounded;
    String status = 'EYES-FREE CANVAS';
    Color color = AppTheme.iceBlue;

    if (state.status == ZeroUiStatus.listening) {
      icon = Icons.mic_rounded;
      status = 'LISTENING...';
    } else if (state.status == ZeroUiStatus.processing) {
      icon = Icons.hourglass_top_rounded;
      status = 'THINKING...';
      color = AppTheme.iceBlue.withValues(alpha: 0.7);
    } else if (state.status == ZeroUiStatus.sosTriggered) {
      icon = Icons.warning_amber_rounded;
      status = 'SOS ACTIVE';
      color = AppTheme.errorRed;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 85),
            const SizedBox(height: 20),
            Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hold anywhere to speak • Swipe down for HUD',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualHudMode(ZeroUiState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'BEACON OS',
                style: TextStyle(
                  color: AppTheme.iceBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(Icons.visibility_rounded, color: AppTheme.iceBlue),
            ],
          ),
          const Spacer(),
          WaveformIndicator(
            soundLevel: state.soundLevel,
            isListening: state.status == ZeroUiStatus.listening,
          ),
          const SizedBox(height: 16),
          LiveTranscriptCard(state: state),
          const SizedBox(height: 12),
          const Text(
            'Triple-tap anywhere for SOS • Swipe up to replay',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}