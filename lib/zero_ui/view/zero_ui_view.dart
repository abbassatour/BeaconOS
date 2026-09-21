// lib/zero_ui/view/zero_ui_view.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/subscription/view/paywall_page.dart';
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

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (state.status != ZeroUiStatus.idle) {
              cubit.replayLastResponse();
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.warmPaper,
            body: HapticCanvas(
              onLongPressStart: cubit.onTouchStarted,
              onLongPressEnd: cubit.onTouchReleased,
              onSwipeUp: cubit.replayLastResponse,
              onSwipeDown: cubit.toggleDisplayMode,
              onTripleTap: cubit.triggerEmergencySos,
              child: SafeArea(
                child: isEyesFree
                    ? _buildEyesFreeMode(state)
                    : _buildVisualHudMode(context, state),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEyesFreeMode(ZeroUiState state) {
    IconData icon = Icons.touch_app_rounded;
    String status = 'EYES-FREE CANVAS';
    Color color = AppTheme.terracotta;

    if (state.status == ZeroUiStatus.listening) {
      icon = Icons.mic_rounded;
      status = 'LISTENING...';
      color = AppTheme.terracotta;
    } else if (state.status == ZeroUiStatus.processing) {
      icon = Icons.hourglass_top_rounded;
      status = 'THINKING...';
      color = AppTheme.warmAmber;
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
              style: TextStyle(color: AppTheme.mutedInk, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualHudMode(BuildContext context, ZeroUiState state) {
    final cubit = context.read<ZeroUiCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BEACON OS',
                style: TextStyle(
                  color: AppTheme.carbonInk,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.terracotta,
                      foregroundColor: AppTheme.cardSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                    label: const Text(
                      'PRO',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(context).push(PaywallPage.route()),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.visibility_off_rounded,
                      color: AppTheme.carbonInk,
                    ),
                    onPressed: cubit.toggleDisplayMode,
                    tooltip: 'Switch to Eyes-Free mode',
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          WaveformIndicator(
            soundLevel: state.soundLevel,
            isListening: state.status == ZeroUiStatus.listening,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showEmulatorCommandDialog(context),
            child: LiveTranscriptCard(state: state),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hold screen to speak • Tap transcript to test quick commands',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mutedInk, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showEmulatorCommandDialog(BuildContext context) {
    final cubit = context.read<ZeroUiCubit>();
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.softBorder, width: 1.5),
        ),
        title: const Text(
          'Quick Command Tester',
          style: TextStyle(
            color: AppTheme.carbonInk,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.carbonInk),
              decoration: const InputDecoration(
                hintText: 'Type or choose a command below...',
                hintStyle: TextStyle(color: AppTheme.mutedInk),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.softBorder),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.terracotta),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip(controller, 'What time is it?'),
                _buildQuickChip(controller, 'What is my battery?'),
                _buildQuickChip(controller, 'Remind me to buy medicine at 5 PM'),
                _buildQuickChip(controller, 'What are my tasks?'),
                _buildQuickChip(controller, 'Note: Meeting with John tomorrow'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedInk)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: AppTheme.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final query = controller.text.trim();
              if (query.isNotEmpty) {
                Navigator.of(ctx).pop();
                cubit.submitQuery(query);
              }
            },
            child: const Text('Run Command', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(TextEditingController controller, String text) {
    return ActionChip(
      backgroundColor: AppTheme.warmPaper,
      side: const BorderSide(color: AppTheme.softBorder),
      label: Text(
        text,
        style: const TextStyle(color: AppTheme.carbonInk, fontSize: 11),
      ),
      onPressed: () => controller.text = text,
    );
  }
}