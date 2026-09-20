// lib/zero_ui/widgets/live_transcript_card.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/zero_ui/cubit/zero_ui_state.dart';
import 'package:flutter/material.dart';

class LiveTranscriptCard extends StatelessWidget {
  const LiveTranscriptCard({
    required this.state,
    super.key,
  });

  final ZeroUiState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isListening = state.status == ZeroUiStatus.listening;
    final isProcessing = state.status == ZeroUiStatus.processing;
    final isSpeaking = state.status == ZeroUiStatus.speaking;

    String header = 'READY';
    Color headerColor = AppTheme.subtleGray;

    if (isListening) {
      header = 'LISTENING...';
      headerColor = AppTheme.iceBlue;
    } else if (isProcessing) {
      header = 'PROCESSING...';
      headerColor = AppTheme.iceBlue.withValues(alpha: 0.6);
    } else if (isSpeaking) {
      header = 'BEACON OS';
      headerColor = AppTheme.pureWhite;
    }

    final displayText = isListening
        ? (state.recognizedText.isEmpty
            ? 'Speak now, holding anywhere...'
            : state.recognizedText)
        : (state.responseText.isEmpty
            ? 'Hold anywhere to speak.\nSwipe up to replay.'
            : state.responseText);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.deepSlate,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: headerColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: headerColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                header,
                style: textTheme.labelLarge?.copyWith(color: headerColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayText,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: isListening ? FontWeight.bold : FontWeight.normal,
              color: isListening ? AppTheme.iceBlue : AppTheme.pureWhite,
            ),
          ),
        ],
      ),
    );
  }
}