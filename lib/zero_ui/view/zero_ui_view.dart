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
                  : _buildVisualHudMode(context, state),
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
                  color: AppTheme.iceBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility_off_rounded, color: AppTheme.iceBlue),
                onPressed: cubit.toggleDisplayMode,
                tooltip: 'Switch to Eyes-Free mode',
              ),
            ],
          ),
          const Spacer(),
          WaveformIndicator(
            soundLevel: state.soundLevel,
            isListening: state.status == ZeroUiStatus.listening,
          ),
          const SizedBox(height: 16),
          // الضغط على البطاقة يفتح نافذة تجربة الأوامر السريعة
          GestureDetector(
            onTap: () => _showEmulatorCommandDialog(context),
            child: LiveTranscriptCard(state: state),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hold screen to speak • Tap transcript to test quick commands',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
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
        backgroundColor: AppTheme.deepSlate,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.iceBlue, width: 1.5),
        ),
        title: const Text(
          'BeaconOS Quick Command Tester',
          style: TextStyle(color: AppTheme.iceBlue, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.pureWhite),
              decoration: const InputDecoration(
                hintText: 'Type or choose a command below...',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.iceBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip(ctx, controller, 'What time is it?'),
                _buildQuickChip(ctx, controller, 'What is my battery?'),
                _buildQuickChip(ctx, controller, 'Remind me to buy medicine at 5 PM'),
                _buildQuickChip(ctx, controller, 'What are my tasks?'),
                _buildQuickChip(ctx, controller, 'Note: Meeting with John tomorrow'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.iceBlue,
              foregroundColor: AppTheme.pureBlack,
            ),
            onPressed: () {
              final query = controller.text.trim();
              if (query.isNotEmpty) {
                Navigator.of(ctx).pop();
                // تنفيذ الأمر ومحاكاة دورة اللمس
                _simulateCommand(cubit, query);
              }
            },
            child: const Text('Run Command', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(BuildContext ctx, TextEditingController controller, String text) {
    return ActionChip(
      backgroundColor: AppTheme.subtleGray,
      label: Text(text, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 11)),
      onPressed: () => controller.text = text,
    );
  }

  void _simulateCommand(ZeroUiCubit cubit, String query) async {
    // محاكاة وضع الإصبع، إدخال النص، ورفع الإصبع
    cubit.emit(cubit.state.copyWith(status: ZeroUiStatus.processing, recognizedText: query));
    final repo = cubit.state;
    // استدعاء المعالجة عبر الكيوبت
    final result = await cubit.repository.dispatchVoiceCommand(query);
    cubit.emit(cubit.state.copyWith(status: ZeroUiStatus.speaking, responseText: result.spokenResponse));
    await cubit.repository.speak(result.spokenResponse);
    cubit.emit(cubit.state.copyWith(status: ZeroUiStatus.idle));
  }
}

// امتداد للوصول إلى الـ repository من داخل الكيوبت
extension on ZeroUiCubit {
  LauncherRepository get repository => (this as dynamic)._repository as LauncherRepository;
}