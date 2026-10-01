// lib/onboarding/blind_flow/view/steps/blind_compass_step.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/onboarding/blind_flow/cubit/blind_onboarding_cubit.dart';
import 'package:beacon_os/onboarding/blind_flow/cubit/blind_onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlindCompassStep extends StatelessWidget {
  const BlindCompassStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BlindOnboardingCubit>();

    return BlocBuilder<BlindOnboardingCubit, BlindOnboardingState>(
      builder: (context, state) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragEnd: (details) {
            final vy = details.primaryVelocity ?? 0;
            if (vy < -250) {
              cubit.handleTrainingSwipeUp();
            } else if (vy > 250) {
              cubit.handleTrainingSwipeDown();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SPATIAL SOUND TRAINING',
                  style: TextStyle(
                    color: AppTheme.cyanHighlight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                // المؤشرات البصرية/الحسية للإتقان
                Column(
                  children: [
                    _buildCheckTile(
                      label: 'Swipe UP ⬆️ to visit Agenda',
                      isMastered: state.hasMasteredNorthSwipe,
                    ),
                    const SizedBox(height: 14),
                    _buildCheckTile(
                      label: 'Swipe DOWN ⬇️ to visit Communications',
                      isMastered: state.hasMasteredSouthSwipe,
                    ),
                    const SizedBox(height: 14),
                    _buildCheckTile(
                      label: 'Pinch 🤏 to dive into Settings Floor',
                      isMastered: state.hasMasteredPinch,
                    ),
                  ],
                ),
                // زر المتابعة يُفعّل بعد تجربة إيماءة واحدة على الأقل
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.hasMasteredNorthSwipe
                          ? AppTheme.cyanHighlight
                          : AppTheme.voidCardSurface,
                      foregroundColor: state.hasMasteredNorthSwipe
                          ? AppTheme.pureBlack
                          : AppTheme.highContrastMuted,
                    ),
                    onPressed: state.hasMasteredNorthSwipe ? cubit.nextStep : null,
                    child: Text(
                      state.hasMasteredNorthSwipe ? 'Next: Test Camera Eyes ➡️' : 'Swipe UP to practice',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckTile({required String label, required bool isMastered}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.voidCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMastered ? AppTheme.cyanHighlight : AppTheme.highContrastBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isMastered ? AppTheme.highContrastText : AppTheme.highContrastMuted,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Icon(
            isMastered ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isMastered ? AppTheme.cyanHighlight : AppTheme.highContrastBorder,
          ),
        ],
      ),
    );
  }
}